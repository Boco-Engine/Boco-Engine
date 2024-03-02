package boco_physics

import "core:simd"
import "core:log"
import "../../types"

TestAABBAABB :: proc(lhs, rhs: AABBVolume) -> bool {
    if (abs(lhs.point[0] - rhs.point[0]) > (lhs.r[0] + rhs.r[0])) do return false
    if (abs(lhs.point[1] - rhs.point[1]) > (lhs.r[1] + rhs.r[1])) do return false
    if (abs(lhs.point[2] - rhs.point[2]) > (lhs.r[2] + rhs.r[2])) do return false
    return true 
}

TestSphereSphere :: proc(lhs, rhs: SphereVolume) {
    
}

// TestAABBAABBSIMD :: proc(lhs: AABBVolumeSIMD, rhs: AABBVolumeSIMD) -> bool {
//     return simd.reduce_or(simd.lanes_gt(simd.abs(simd.sub(lhs.point, rhs.point)), simd.add(lhs.r, rhs.r))) == 0
// }

// TestSphereSphereSIMD :: proc(lhs: SphereVolumeSIMD, rhs: SphereVolumeSIMD) -> bool {
//     r_sum := lhs.radius + rhs.radius
//     res := simd.sub(lhs.point, rhs.point)
//     dist := simd.reduce_add_ordered(simd.mul(res, res))
//     return (r_sum * r_sum) >  dist
// }