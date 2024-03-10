package window

import "core:log"

import sdl "vendor:sdl2"

ViewArea :: struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,
    // TODO: needs a surface
}