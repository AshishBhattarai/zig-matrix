const std = @import("std");
const testing = std.testing;
const GenericVector = @import("vector.zig").GenericVector;

/// Provides column-major 2x2, 3x3 and 4x4 matrix implementation with some learn algerba capabilities
pub fn GenericMatrix(comptime dim_col_i: comptime_int, comptime dim_row_i: comptime_int, comptime Scalar: type) type {
    const Vec3 = GenericVector(3, Scalar);
    const Vec2 = GenericVector(2, Scalar);

    return extern struct {
        const Self = @This();
        pub const RowVec = GenericVector(dim_row, Scalar);
        pub const ColVec = GenericVector(dim_col, Scalar);
        pub const dim = dim_col * dim_row;
        pub const dim_col = dim_col_i;
        pub const dim_row = dim_row_i;

        elements: [dim_col]RowVec,

        pub usingnamespace switch (Self) {
            GenericMatrix(2, 2, Scalar) => struct {
                /// Initialize 2x2 column-major matrix with row vectors
                pub inline fn init(r0: RowVec, r1: RowVec) Self {
                    return .{ .elements = .{ r0, r1 } };
                }

                /// Initialize 2x2 column-major identity matrix
                pub inline fn identity() Self {
                    return .{ .elements = .{
                        RowVec.init(1, 0),
                        RowVec.init(0, 1),
                    } };
                }

                /// Initialize 2x2 column-major matrix from array slice
                pub inline fn fromSlice(data: *const [dim]Scalar) Self {
                    return .{ .elements = .{
                        RowVec.init(data[0], data[1]),
                        RowVec.init(data[2], data[3]),
                    } };
                }

                /// Transpose into a new 2x2 matrix
                pub inline fn transpose(self: Self) Self {
                    return .{ .elements = .{ self.row(0), self.row(1) } };
                }

                /// Computes determinant of 2x2 matrix
                pub inline fn determinant(self: Self) Scalar {
                    return self.elements[0].x() * self.elements[1].y() - self.elements[1].x() * self.elements[0].y();
                }

                /// Computes inverse of 2x2 matrix
                pub inline fn inverse(self: Self) Self {
                    const det = self.determinant();
                    return .{ .elements = .{
                        RowVec.init(self.elements[1].y(), -self.elements[0].y()).divScalar(det),
                        RowVec.init(-self.elements[1].x(), self.elements[0].x()).divScalar(det),
                    } };
                }
            },
            GenericMatrix(3, 3, Scalar) => struct {
                /// Initialize 3x3 column-major matrix with row vectors
                pub inline fn init(r0: RowVec, r1: RowVec, r2: RowVec) Self {
                    return .{ .elements = .{ r0, r1, r2 } };
                }

                /// Initialize 3x3 column-major identity matrix
                pub inline fn identity() Self {
                    return .{ .elements = .{
                        RowVec.init(1, 0, 0),
                        RowVec.init(0, 1, 0),
                        RowVec.init(0, 0, 1),
                    } };
                }

                /// Initialize 3x3 column-major matrix from array slice
                pub inline fn fromSlice(data: *const [dim]Scalar) Self {
                    return .{ .elements = .{
                        RowVec.init(data[0], data[1], data[2]),
                        RowVec.init(data[3], data[4], data[5]),
                        RowVec.init(data[6], data[7], data[8]),
                    } };
                }

                /// Transpose into a new 3x3 matrix
                pub inline fn transpose(self: Self) Self {
                    return .{ .elements = .{ self.row(0), self.row(1), self.row(2) } };
                }

                /// Compute determinant of 3x3 matrix
                pub inline fn determinant(self: Self) Scalar {
                    const m0 = self.elements[0].elements *
                        self.elements[1].swizzle("yzx").elements *
                        self.elements[2].swizzle("zxy").elements;
                    const m1 = self.elements[0].swizzle("yxz").elements *
                        self.elements[1].swizzle("xzy").elements *
                        self.elements[2].swizzle("zyx").elements;
                    return @reduce(.Add, m0 - m1);
                }

                /// Compute 3x3 column-major homogeneous 2D transformation matrix
                pub inline fn fromTranslation(vec: Vec2) Self {
                    return .{ .elements = .{
                        RowVec.init(1, 0, 0),
                        RowVec.init(0, 1, 0),
                        RowVec.init(vec.x(), vec.y(), 1),
                    } };
                }

                /// Compute 3x3 column-major homogeneous 2D rotation matrix
                pub inline fn fromRotation(angle: Scalar) Self {
                    const cos_angle = @cos(angle);
                    const sin_angle = @sin(angle);

                    return .{ .elements = .{
                        RowVec.init(cos_angle, -sin_angle, 0),
                        RowVec.init(sin_angle, cos_angle, 0),
                        RowVec.init(0, 0, 1),
                    } };
                }

                /// Compute 3x3 column-major homogeneous 2D scale matrix
                pub inline fn fromScale(vec: Vec2) Self {
                    return .{ .elements = .{
                        RowVec.init(vec.x(), 0, 0),
                        RowVec.init(0, vec.y(), 0),
                        RowVec.init(0, 0, 1),
                    } };
                }

                /// Applies 2D translation and returns a new matrix
                pub inline fn translate(self: Self, vec: Vec2) Self {
                    return Self.mul(fromTranslation(vec), self);
                }

                /// Applies 2D rotation and returns a new matrix
                pub inline fn rotate(self: Self, angle: Scalar) Self {
                    return Self.mul(fromRotation(angle), self);
                }

                /// Applies 2D scale and returns a new matrix
                pub inline fn scale(self: Self, vec: Vec2) Self {
                    return Self.mul(fromScale(vec), self);
                }

                // Applies 2D translation, scale and rotation and returns a new matrix
                pub inline fn transformation(translationv: Vec2, rotationv: Scalar, scalev: Vec2) Self {
                    const cos_rot = @cos(rotationv);
                    const sin_rot = @sin(rotationv);
                    return .{ .elements = .{
                        RowVec.init(scalev.x() * cos_rot, scalev.x() * sin_rot, 0),
                        RowVec.init(-scalev.y() * sin_rot, scalev.y() * cos_rot, 0),
                        RowVec.init(translationv.x(), translationv.y(), 1),
                    } };
                }

                /// Extract vec2 translation from matrix
                pub inline fn getTranslation(self: Self) Vec2 {
                    return self.elements[2].swizzle("xy");
                }

                /// Extract rotation angle from matrix
                pub inline fn getRotation(self: Self) Scalar {
                    return std.math.atan2(self.elements[1][0], self.elements[0][0]);
                }

                /// Extract vec2 scale from matrix
                pub inline fn getScale(self: Self) Vec2 {
                    return Vec2.init(self.elements[0].swizzle("xy").len(), self.elements[1].swizzle("xy").len());
                }
            },
            GenericMatrix(4, 4, Scalar) => struct {
                /// Initialize 4x4 column-major matrix with row vectors
                pub inline fn init(r0: RowVec, r1: RowVec, r2: RowVec, r3: RowVec) Self {
                    return .{ .elements = .{ r0, r1, r2, r3 } };
                }

                /// Initialize 4x4 identity matrix with row vectors
                pub inline fn identity() Self {
                    return .{ .elements = .{
                        RowVec.init(1, 0, 0, 0),
                        RowVec.init(0, 1, 0, 0),
                        RowVec.init(0, 0, 1, 0),
                        RowVec.init(0, 0, 0, 1),
                    } };
                }

                /// Initialize 4x4 column-major matrix 3x3 matrix, r3 row vector
                pub inline fn fromMat3(mat3: GenericMatrix(3, 3, Scalar), r3: RowVec) Self {
                    return Self.init(
                        RowVec.fromVec3(mat3.elements[0], 0),
                        RowVec.fromVec3(mat3.elements[1], 0),
                        RowVec.fromVec3(mat3.elements[2], 0),
                        r3,
                    );
                }

                pub inline fn toMat3(self: Self) GenericMatrix(3, 3, Scalar) {
                    return GenericMatrix(3, 3, Scalar).init(
                        self.elements[0].swizzle("xyz"),
                        self.elements[1].swizzle("xyz"),
                        self.elements[2].swizzle("xyz"),
                    );
                }

                /// Compute 4x4 column-major homogeneous 2D scale matrix
                pub inline fn fromSlice(data: *const [dim]Scalar) Self {
                    return .{ .elements = .{
                        RowVec.init(data[0], data[1], data[2], data[3]),
                        RowVec.init(data[4], data[5], data[6], data[7]),
                        RowVec.init(data[8], data[9], data[10], data[11]),
                        RowVec.init(data[12], data[13], data[14], data[15]),
                    } };
                }

                /// Transpose into a new 3x3 matrix
                pub inline fn transpose(self: Self) Self {
                    return .{ .elements = .{ self.row(0), self.row(1), self.row(2), self.row(3) } };
                }

                /// Compute determinant of 4x4 matrix
                pub inline fn determinant(self: Self) Scalar {
                    const m0 = self.elements[2].swizzle("zyyx").mul(self.elements[3].swizzle("wwzw"));
                    const m1 = self.elements[2].swizzle("wwzw").mul(self.elements[3].swizzle("zyyx"));
                    const sub0 = m0.sub(m1);

                    const m2 = self.elements[2].swizzle("zyxx").mul(self.elements[3].swizzle("xxzy"));
                    const m3 = m2.swizzle("zwzw");
                    const sub1 = m3.sub(m2);

                    const m4 = sub0.swizzle("xxyz").mul(self.elements[1].swizzle("yxxx"));
                    const subTemp0 = sub0.shuffle(sub1, [_]i32{ 1, 3, 3, -1 });
                    const m5 = subTemp0.mul(self.elements[1].swizzle("zzyy"));
                    const subRes2 = m4.sub(m5);

                    const subTemp1 = sub0.shuffle(sub1, [_]i32{ 2, -1, -2, -2 });
                    const m6 = subTemp1.mul(self.elements[1].swizzle("wwwz"));

                    const add = subRes2.add(m6);
                    const det = add.mul(RowVec.init(1.0, -1.0, 1.0, -1.0));

                    return self.elements[0].dot(det);
                }

                /// Compute 4x4 column-major homogeneous 3D transformation matrix
                pub inline fn fromTranslation(vec: Vec3) Self {
                    return init(
                        RowVec.init(1, 0, 0, 0),
                        RowVec.init(0, 1, 0, 0),
                        RowVec.init(0, 0, 1, 0),
                        RowVec.init(vec.x(), vec.y(), vec.z(), 1),
                    );
                }

                /// Compute 4x4 column-major homogeneous 3D rotation matrix around given axis
                /// Doesn't normalize the axis
                /// based on: https://www.songho.ca/opengl/gl_rotate.html
                pub inline fn fromRotation(angle: Scalar, axis: Vec3) Self {
                    const cos_angle = @cos(angle);
                    const sin_angle = @sin(angle);
                    const cos_value = 1.0 - cos_angle;

                    const xx = axis.x() * axis.x();
                    const xy = axis.x() * axis.y();
                    const xz = axis.x() * axis.z();
                    const yy = axis.y() * axis.y();
                    const yz = axis.y() * axis.z();
                    const zz = axis.z() * axis.z();
                    const sx = sin_angle * axis.x();
                    const sy = sin_angle * axis.y();
                    const sz = sin_angle * axis.z();

                    return .{ .elements = .{
                        RowVec.init(xx * cos_value + cos_angle, xy * cos_value - sz, xz * cos_value + sy, 0),
                        RowVec.init(xy * cos_value + sz, yy * cos_value + cos_angle, yz * cos_value - sx, 0),
                        RowVec.init(xz * cos_value - sy, yz * cos_value + sx, zz * cos_value + cos_angle, 0),
                        RowVec.init(0, 0, 0, 1),
                    } };
                }

                /// Compute 4x4 column-major homogeneous 3D rotation matrix from given euler_angle
                /// zyx order, mat = (z * y * x)
                pub inline fn fromEulerAngles(euler_angle: Vec3) Self {
                    const cos_euler = euler_angle.cos();
                    const sin_euler = euler_angle.sin();

                    return .{ .elements = .{
                        RowVec.init(
                            cos_euler.z() * cos_euler.y(),
                            cos_euler.z() * sin_euler.y() * sin_euler.x() - sin_euler.z() * cos_euler.x(),
                            cos_euler.z() * sin_euler.y() * cos_euler.x() + sin_euler.z() * sin_euler.x(),
                            0,
                        ),
                        RowVec.init(
                            sin_euler.z() * cos_euler.y(),
                            sin_euler.z() * sin_euler.y() * sin_euler.x() + cos_euler.z() * cos_euler.x(),
                            sin_euler.z() * sin_euler.y() * cos_euler.x() - cos_euler.z() * sin_euler.x(),
                            0,
                        ),
                        RowVec.init(-sin_euler.y(), cos_euler.y() * sin_euler.x(), cos_euler.y() * cos_euler.x(), 0),
                        RowVec.init(0, 0, 0, 1),
                    } };
                }

                /// Compute 4x4 column-major homogeneous 3D scale matrix
                pub inline fn fromScale(vec: Vec3) Self {
                    return init(
                        RowVec.init(vec.x(), 0, 0, 0),
                        RowVec.init(0, vec.y(), 0, 0),
                        RowVec.init(0, 0, vec.z(), 0),
                        RowVec.init(0, 0, 0, 1),
                    );
                }

                /// Applies 3D translation and returns a new matrix
                pub inline fn translate(self: Self, vec: Vec3) Self {
                    return Self.mul(fromTranslation(vec), self);
                }

                /// Applies 3D rotation and returns a new matrix
                pub inline fn rotate(self: Self, angle: Scalar, axis: Vec3) Self {
                    return Self.mul(fromRotation(angle, axis), self);
                }

                /// Applies 3D scale and returns a new matrix
                pub inline fn scale(self: Self, vec: Vec3) Self {
                    return Self.mul(fromScale(vec), self);
                }

                // Applies 3D translation, scale and rotation and returns a new matrix
                pub inline fn transformation(translationv: Vec3, rotationv: Vec3, scalev: Vec3) Self {
                    const cos_rot = rotationv.cos();
                    const sin_rot = rotationv.sin();
                    return .{ .elements = .{
                        RowVec.init(
                            cos_rot.z() * cos_rot.y() * scalev.x(),
                            (cos_rot.z() * sin_rot.y() * sin_rot.x() - sin_rot.z() * cos_rot.x()) * scalev.y(),
                            (cos_rot.z() * sin_rot.y() * cos_rot.x() + sin_rot.z() * sin_rot.x()) * scalev.z(),
                            0,
                        ),
                        RowVec.init(
                            sin_rot.z() * cos_rot.y() * scalev.x(),
                            (sin_rot.z() * sin_rot.y() * sin_rot.x() + cos_rot.z() * cos_rot.x()) * scalev.y(),
                            (sin_rot.z() * sin_rot.y() * cos_rot.x() - cos_rot.z() * sin_rot.x()) * scalev.z(),
                            0,
                        ),
                        RowVec.init(
                            -sin_rot.y() * scalev.x(),
                            cos_rot.y() * sin_rot.x() * scalev.y(),
                            cos_rot.y() * cos_rot.x() * scalev.z(),
                            0,
                        ),
                        RowVec.fromVec3(translationv, 1.0),
                    } };
                }

                /// Extract vec3 translation from matrix
                pub inline fn getTranslation(self: Self) Vec3 {
                    return self.elements[3].swizzle("xyz");
                }

                /// Extract rotation euler angle from matrix
                pub inline fn getRotation(self: Self) Vec3 {
                    const col_a = self.elements[0].swizzle("xyz").norm();
                    const col_b = self.elements[1].swizzle("xyz").norm();
                    const col_c = self.elements[2].swizzle("xyz").norm();

                    const theta_x = std.math.atan2(col_c.y(), col_c.z());
                    const c2 = @sqrt(col_a.x() * col_a.x() + col_b.x() * col_b.x());
                    const theta_y = std.math.atan2(-col_c.x(), c2);
                    const s1 = @sin(theta_x);
                    const c1 = @cos(theta_x);
                    const theta_z = std.math.atan2(s1 * col_a.z() - c1 * col_a.y(), c1 * col_b.y() - s1 * col_b.z());

                    return Vec3.init(theta_x, theta_y, theta_z);
                }

                /// Extract vec3 scale from matrix
                pub inline fn getScale(self: Self) Vec3 {
                    return Vec3.init(
                        self.elements[0].swizzle("xyz").len(),
                        self.elements[1].swizzle("xyz").len(),
                        self.elements[2].swizzle("xyz").len(),
                    );
                }

                /// orthographic projection to NDC x=[-1, +1], y = [-1, +1] and z = [0, +1]
                pub inline fn projection2D(left: Scalar, right: Scalar, bottom: Scalar, top: Scalar, near: Scalar, far: Scalar) Self {
                    const x_diff = right - left;
                    const y_diff = top - bottom;
                    const z_diff = far - near;
                    return .{ .elements = .{
                        RowVec.init(2 / x_diff, 0, 0, 0),
                        RowVec.init(0, 2 / y_diff, 0, 0),
                        RowVec.init(0, 0, 1 / z_diff, 0),
                        RowVec.init((right + left) / x_diff, (top + bottom) / y_diff, (far + near) / z_diff, 1),
                    } };
                }

                /// perspective projection to NDC x=[-1, +1], y = [-1, +1] and z = [0, +1] with vertical FOV and reversedZ
                pub inline fn perspectiveY(fov: Scalar, aspect_ratio: Scalar, near: Scalar, far: Scalar) Self {
                    const tangent = @tan(fov * 0.5);
                    const focal_length = 1 / tangent;
                    const A = near / (far - near);

                    return .{ .elements = .{
                        RowVec.init(focal_length / aspect_ratio, 0, 0, 0),
                        RowVec.init(0, -focal_length, 0, 0),
                        RowVec.init(0, 0, A, -1.0),
                        RowVec.init(0, 0, far * A, 0),
                    } };
                }

                /// perspective projection to NDC x=[-1, +1], y = [-1, +1] and z = [0, +1] with horizontal FOV and ReversedZ
                pub inline fn perspectiveX(fov: Scalar, aspect_ratio: Scalar, near: Scalar, far: Scalar) Self {
                    const tangent = @tan(fov * 0.5);
                    const focal_length = 1 / tangent;
                    const A = near / (far - near);

                    return .{ .elements = .{
                        RowVec.init(focal_length, 0, 0, 0),
                        RowVec.init(0, -focal_length * aspect_ratio, 0, 0),
                        RowVec.init(0, 0, A, -1.0),
                        RowVec.init(0, 0, far * A, 0),
                    } };
                }
            },
            else => @compileError("Invalid matrix dimensions"),
        };

        pub inline fn mul(a: Self, b: anytype) @TypeOf(b) {
            comptime {
                if (!(std.mem.startsWith(u8, @typeName(@TypeOf(b)), "matrix") or
                    std.mem.startsWith(u8, @typeName(@TypeOf(b)), "vector")))
                    @compileError("b must be either vector or matrix.");
                if (@TypeOf(b).dim_row != dim_col)
                    @compileError("multiplication not possible: a.dim_col != b.dim_row");
            }
            const is_vec = comptime std.mem.startsWith(u8, @typeName(@TypeOf(b)), "vector");

            var result: @TypeOf(b) = undefined;
            if (is_vec) {
                var sum: RowVec = RowVec.shuffle(b, undefined, [_]u32{0} ** dim_row).mul(a.col(0));
                inline for (1..dim_row) |row_idx| {
                    const b_col_i = RowVec.shuffle(b, undefined, [_]u32{row_idx} ** dim_row);
                    const col_mul = b_col_i.mul(a.col(row_idx));
                    sum = sum.add(col_mul);
                }
                result = sum;
            } else {
                inline for (0..@TypeOf(b).dim_col) |col_idx| {
                    const b_col = b.col(col_idx);
                    var sum: RowVec = RowVec.shuffle(b_col, undefined, [_]u32{0} ** dim_row).mul(a.col(0));
                    inline for (1..dim_row) |row_idx| {
                        const b_col_i = RowVec.shuffle(b_col, undefined, [_]u32{row_idx} ** dim_row);
                        const col_mul = b_col_i.mul(a.col(row_idx));
                        sum = sum.add(col_mul);
                    }
                    result.elements[col_idx] = sum;
                }
            }
            return result;
        }

        /// Fetch row vector from give column index
        pub inline fn col(self: Self, idx: u32) RowVec {
            return self.elements[idx];
        }

        /// Fetch column vector from give row index
        pub inline fn row(self: Self, row_idx: u32) ColVec {
            var result: ColVec = undefined;
            inline for (0..dim_col) |col_idx| {
                result.elements[col_idx] = self.elements[col_idx].elements[row_idx];
            }
            return result;
        }

        pub inline fn element(self: Self, col_idx: u32, row_idx: u32) Scalar {
            return self.elements[col_idx].elements[row_idx];
        }

        pub inline fn splat(value: Scalar) Self {
            return .{ .elements = .{RowVec.splat(value)} ** dim_col };
        }
    };
}

test "determinant" {
    // Mat2x2
    {
        const Mat2x2 = GenericMatrix(2, 2, f32);
        const vec2 = GenericVector(2, f32).init;

        const a = Mat2x2.init(
            vec2(3, 4),
            vec2(8, 6),
        );

        try testing.expectEqual(-14, a.determinant());
    }
    // Mat3x3
    {
        const Mat3x3 = GenericMatrix(3, 3, f32);
        const vec3 = GenericVector(3, f32).init;

        const a = Mat3x3.init(
            vec3(6, 4, 2),
            vec3(1, -2, 8),
            vec3(1, 5, 7),
        );

        try testing.expectEqual(-306, a.determinant());
    }
    // Mat4x4
    {
        const Mat4x4 = GenericMatrix(4, 4, f32);
        const Vec4 = GenericVector(4, f32).init;

        const a = Mat4x4.init(
            Vec4(8, 7, 3, 9),
            Vec4(73, 9, 4, 1),
            Vec4(2, 1, 7, 4),
            Vec4(34, 2, 8, 7),
        );

        try testing.expectEqual(-19316, a.determinant());
    }
}

test "transpose" {
    const Mat4x4 = GenericMatrix(4, 4, f32);
    const vec4 = GenericVector(4, f32).init;

    const a = Mat4x4.init(
        vec4(10, -5, 6, -2),
        vec4(0, -1, 0, 9),
        vec4(-1, 6, -4, 8),
        vec4(9, -8, -6, -10),
    );

    const expected = Mat4x4.init(
        vec4(10, 0, -1, 9),
        vec4(-5, -1, 6, -8),
        vec4(6, 0, -4, -6),
        vec4(-2, 9, 8, -10),
    );

    try testing.expectEqual(expected, a.transpose());
}

test "row" {
    const Mat4x4 = GenericMatrix(4, 4, f32);
    const vec4 = GenericVector(4, f32).init;

    const a = Mat4x4.init(
        vec4(10, -5, 6, -2),
        vec4(0, -1, 0, 9),
        vec4(-1, 6, -4, 8),
        vec4(9, -8, -6, -10),
    );

    try testing.expectEqual(vec4(10, 0, -1, 9), a.row(0));
}

test "col" {
    const Mat4x4 = GenericMatrix(4, 4, f32);
    const vec4 = GenericVector(4, f32).init;

    const a = Mat4x4.init(
        vec4(10, -5, 6, -2),
        vec4(0, -1, 0, 9),
        vec4(-1, 6, -4, 8),
        vec4(9, -8, -6, -10),
    );

    try testing.expectEqual(vec4(10, -5, 6, -2), a.col(0));
}

test "mul" {
    const Mat4x4 = GenericMatrix(4, 4, f32);
    const Vec4 = GenericVector(4, f32);

    // Mat4x4
    {
        const a = Mat4x4.init(
            Vec4.init(0, 1, 2, 3),
            Vec4.init(4, 5, 6, 7),
            Vec4.init(8, 9, 10, 11),
            Vec4.init(12, 13, 14, 15),
        );
        const b = Mat4x4.init(
            Vec4.init(4, 5, 6, 7),
            Vec4.init(1, 2, 3, 4),
            Vec4.init(9, 10, 11, 12),
            Vec4.init(-1, -2, -3, -4),
        );

        const expected = Mat4x4.init(
            Vec4.init(152, 174, 196, 218),
            Vec4.init(80, 90, 100, 110),
            Vec4.init(272, 314, 356, 398),
            Vec4.init(-80, -90, -100, -110),
        );
        try testing.expectEqual(expected, Mat4x4.mul(a, b));
    }

    // Mat4x4 x Vec4
    {
        const a = Mat4x4.init(
            Vec4.init(1, 18, 102, 79),
            Vec4.init(-1, -30, 46, -47),
            Vec4.init(-120, 76, -56, 74),
            Vec4.init(102, -9, 26, -37),
        );
        const b = Vec4.init(7, -7, -3, -8);

        try testing.expectEqual(Vec4.init(-442, 180, 352, 956), Mat4x4.mul(a, b));
    }
}

test "extractRotation" {
    // Mat4x4
    {
        const Mat4x4 = GenericMatrix(4, 4, f32);
        const Vec3 = GenericVector(3, f32);

        const a = Mat4x4.fromEulerAngles(Vec3.init(0.785398, -0.0872665, 0.349066));
        try std.testing.expectEqual(Vec3.init(0.785398, -0.0872665, 0.349066), a.getRotation());
    }
}

test "rotate" {
    // Mat4x4
    {
        const Mat4x4 = GenericMatrix(4, 4, f32);
        const Vec3 = GenericVector(3, f32);

        const a = Mat4x4.identity().rotate(0.785398, Vec3.init(0, 1, 0));
        try std.testing.expectEqual(Vec3.init(0, 0.785398, 0), a.getRotation());
    }
}

test "transformation" {
    // Mat4x4
    {
        const Mat4x4 = GenericMatrix(4, 4, f32);
        const Vec3 = GenericVector(3, f32);

        const position = Vec3.init(20, 40, -50);
        const rotation = Vec3.init(0.785398, -0.0872665, 0.349066);
        const scale = Vec3.init(4, 4, 4);

        const a = Mat4x4.transformation(position, rotation, scale);
        try std.testing.expectEqual(position, a.getTranslation());
        try std.testing.expectEqual(rotation, a.getRotation());
        try std.testing.expectEqual(scale, a.getScale());
    }
}

test "inverse" {
    const Mat2x2 = GenericMatrix(2, 2, f32);
    const Vec2 = Mat2x2.RowVec;

    const a = Mat2x2.init(Vec2.init(4, 2), Vec2.init(7, 6)).inverse();
    try std.testing.expectEqual(Mat2x2.init(Vec2.init(0.6, -0.2), Vec2.init(-0.7, 0.4)), a);
}
