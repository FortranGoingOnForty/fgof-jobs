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

Sprint 01 is in place.

Tracked today:

- package layout, CI, and standalone repo setup
- foundational job types for specs, handles, and results
- explicit configure, attach, complete, and release lifecycle helpers
- ownership and cleanup-boundary helpers for later wait and process-group work
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
- `make_job_spec`
- `configure_job`
- `attach_job`
- `complete_job`
- `release_job`
- `job_is_configured`
- `job_is_running`
- `job_is_finished`
- `job_needs_cleanup`
- `jobs_backend_name`

Current semantics:

- `job_spec` carries the intended command, argument vector, and foreground/background intent
- `make_job_spec()` builds a reusable spec value for later launch or attach work
- `configure_job()` resets a handle into a configured-but-not-running state from a spec
- `attach_job()` records pid/process-group identity for an already launched job and establishes ownership expectations
- `complete_job()` stores a terminal result and clears runtime cleanup obligations
- `release_job()` drops cleanup ownership while preserving runtime tracking metadata
- `job_is_configured()`, `job_is_running()`, `job_is_finished()`, and `job_needs_cleanup()` expose the first stable lifecycle predicates
- `job_handle` is now the explicit ownership point for a launched job or process group
- `job_result` is the shape for terminal exit/signal/stop status reporting once a result becomes available
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
