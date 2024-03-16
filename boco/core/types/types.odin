package types

import "core:simd"

Vec3 :: [3]f32
dVec3 :: [3]f64
iVec3 :: [3]i32
uVec3 :: [3]u32
Vec3SIMD :: #simd[4]f32

Vec4 :: [4]f32
dVec4 :: [4]f64
iVec4 :: [4]i32
uVec4 :: [4]u32
Vec4SIMD :: #simd[4]f32

Mat4 :: matrix[4, 4]f32