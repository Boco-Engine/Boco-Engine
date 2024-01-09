package benchmarks

import "core:time"

BenchmarkSettings :: struct {
    setup: #type proc(settings: ^BenchmarkSettings) -> bool,
    benched_proc: #type proc(settings: ^BenchmarkSettings) -> bool,
    cleanup: #type proc(settings: ^BenchmarkSettings) -> bool,

    run_count: u32,
    input: []u8,
    output: []u8,

    // Results
    total_duration: time.Duration
}

benchmark :: proc(settings: ^BenchmarkSettings) -> bool {
    assert(settings != nil, "Nil settings, must be a pointer to a valid BenchmarkSettings struct.")
    assert(settings.benched_proc != nil, "No procedure provided to benchmark.")

    if settings.setup != nil {
        settings->setup() or_return
    }

    total: time.Duration
    {
        time.SCOPED_TICK_DURATION(&total)
        for i in 0..<settings.run_count {
            settings->benched_proc() or_return
        }
    }
    settings.total_duration = total

    if settings.cleanup != nil {
        settings->cleanup() or_return
    }

    return true
}