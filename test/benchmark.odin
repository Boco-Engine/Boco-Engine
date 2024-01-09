package test

import "core:time"
import "core:fmt"
import "core:log"
import "../src"
import "../src/boco_core/boco_renderer"

renderer: boco_renderer.Renderer

setup :: proc(options: ^time.Benchmark_Options, allocator := context.allocator) -> (err: time.Benchmark_Error) {
    boco_renderer.init_renderer(&renderer)
    return
}

setup2 :: proc() {
    boco_renderer.init_renderer(&renderer)
    return
}

bench :: proc(options: ^time.Benchmark_Options, allocator := context.allocator) -> (err: time.Benchmark_Error) {
    boco_renderer.query_best_device(&renderer)
    return
}

bench2 :: proc() {
    boco_renderer.query_best_device(&renderer)
    return
}

teardown :: proc(options: ^time.Benchmark_Options, allocator := context.allocator) -> (err: time.Benchmark_Error) {
    boco_renderer.cleanup_renderer(&renderer)
    return
}

teardown2 :: proc() {
    boco_renderer.cleanup_renderer(&renderer)
    return
}

main :: proc() {
    benchmark_settings : time.Benchmark_Options
    benchmark_settings.count = 1000
    benchmark_settings.setup = setup
    benchmark_settings.bench = bench
    benchmark_settings.teardown = teardown
    time.benchmark(&benchmark_settings)
    fmt.println(time.duration_milliseconds(benchmark_settings.duration))

    setup2()
    fmt.println(time.duration_milliseconds(benchmark_proc(bench2, 1000)))
    teardown2()
}

benchmark_proc :: proc(procedure: proc(), runs: i64) -> (total: time.Duration) {
    for i in 0..<runs {
        diff: time.Duration
        {
            time.SCOPED_TICK_DURATION(&diff)
            procedure()
        }
        total += diff / cast(time.Duration)runs
    }
	return
}