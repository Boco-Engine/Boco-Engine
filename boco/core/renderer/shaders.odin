package renderer

import "core:os"
import "core:c/libc"
import "core:strings"
import "core:path/filepath"
import "core:log"

// NOTE: Do we want our own or just use vulkan enum?
ShaderStage :: enum {
    VERTEX,
    FRAGMENT,
    COMPUTE,
    TESSELLATION_EVALUATION,
    TESSELLATION_CONTROL,
    GEOMETRY,
}

Shader :: struct {
    path: string,
    entry: string,
    inputs: ShaderInputs,
    stage: ShaderStage,
    constants: map[string]string, // Values in the shader to write in before compiling
}

// DESIGN: Figure out how to store this is a resonable way.
ShaderInputs :: struct {
    push_constants: typeid,
    samplers: u32,
    uniform_buffers: u32
}

// NOTE: current system requires having glslc in the path.
compile_shader :: proc(path: string) {
    cmd := strings.builder_make()
    strings.write_string(&cmd, "glslc ")
    strings.write_string(&cmd, path)
    strings.write_string(&cmd, " -o Shaders/compiled/")
    strings.write_string(&cmd, filepath.base(path))
    strings.write_string(&cmd, ".spv")
    log.debug(strings.to_string(cmd))
    libc.system(strings.clone_to_cstring(strings.to_string(cmd), context.temp_allocator))

    strings.builder_destroy(&cmd)
}