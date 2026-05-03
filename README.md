# fgof-jobs

Background job, process-group, and wait-model helpers for modern Fortran.

`fgof-jobs` is intended to be a small, standalone library for the parts of job
control that shells, supervisors, and long-running tool hosts usually end up
rebuilding locally.

It is part of the [FortranGoingOnForty lib-modules](https://github.com/FortranGoingOnForty/lib-modules)
catalog, but it is intended to stand on its own as a normal `fpm` package.

Current v1 target:

- stable job spec, job handle, and job result types
- job-state helpers that can support foreground and background process groups
- room for wait, signal, and pipeline helpers without forcing shell UI policy

Future scope:

- pipeline helpers layered over `fgof-process`
- signal and terminal handoff helpers
- examples for shell-like and tool-runner workflows

## Status

Initial scaffold is in place.

Tracked today:

- package layout, CI, and standalone repo setup
- foundational job types for specs, handles, and results
- backend naming scaffold for a future POSIX-first implementation
- focused scaffold coverage in `fpm test`

## Public API Shape

Primary modules:

- `fgof_jobs`
- `fgof_jobs_types`

Public types:

- `job_spec`
- `job_handle`
- `job_result`

Current public procedures:

- `clear_job_spec`
- `clear_job_handle`
- `clear_job_result`
- `jobs_backend_name`

Current semantics:

- `job_spec` carries the intended command, argument vector, and foreground/background intent
- `job_handle` is the future ownership point for a launched job or process group
- `job_result` is the future shape for wait/exit/signal status reporting
- `jobs_backend_name()` currently reports the planned backend family and exists to stabilize the package surface early

## Build And Test

```bash
fpm test
```

## Supported Platforms

- macOS
- Linux

## Boundaries

- intended to stay independently versioned and releasable
- focused on reusable job-control mechanics first, not full shell policy
- should remain useful on its own even if future shells or supervisors build on top

## License

MIT
