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

Sprint 02 is in place.

Tracked today:

- package layout, CI, and standalone repo setup
- foundational job types for specs, handles, and results
- explicit configure, attach, complete, and release lifecycle helpers
- explicit process-group ownership tracking on job handles
- wait-result constructors for exited, signaled, stopped, and continued outcomes
- state-transition helpers that distinguish stopped jobs from terminal jobs
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
- `observe_wait_result`
- `release_job`
- `job_exit_result`
- `job_signal_result`
- `job_stop_result`
- `job_continue_result`
- `job_is_configured`
- `job_is_running`
- `job_is_stopped`
- `job_is_finished`
- `job_needs_cleanup`
- `job_owns_process_group`
- `jobs_backend_name`

Current semantics:

- `job_spec` carries the intended command, argument vector, and foreground/background intent
- `make_job_spec()` builds a reusable spec value for later launch or attach work
- `configure_job()` resets a handle into a configured-but-not-running state from a spec
- `attach_job()` records pid/process-group identity for an already launched job and establishes both process and process-group ownership expectations
- `job_exit_result()`, `job_signal_result()`, `job_stop_result()`, and `job_continue_result()` build explicit wait outcomes for later launch or wait backends
- `observe_wait_result()` applies non-terminal and terminal wait state transitions to a tracked handle
- `complete_job()` now models terminal completion only and clears runtime cleanup obligations after exit or signal outcomes
- `release_job()` drops cleanup ownership while preserving runtime tracking metadata
- `job_is_configured()`, `job_is_running()`, `job_is_stopped()`, `job_is_finished()`, `job_needs_cleanup()`, and `job_owns_process_group()` expose the current stable lifecycle predicates
- `job_handle` is now the explicit ownership point for a launched job or process group
- `job_result` now carries pid/process-group identity plus exited, signaled, stopped, and continued wait outcomes
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
