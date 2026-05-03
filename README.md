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

Sprint 04 is in place.

Tracked today:

- package layout, CI, and standalone repo setup
- foundational job types for specs, handles, and results
- explicit configure, attach, complete, and release lifecycle helpers
- explicit process-group ownership tracking on job handles
- wait-result constructors for exited, signaled, stopped, and continued outcomes
- state-transition helpers that distinguish stopped jobs from terminal jobs
- grouped pipeline-member tracking on job handles
- explicit signal-forwarding and terminal-handoff policy fields
- pipeline-aware stop, continue, and completion aggregation
- tracked examples for lifecycle and pipeline state transitions
- replacement-safe pipeline member attachment and cleaner group-stop member results
- CI now runs both tests and tracked examples

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
- `attach_pipeline_members`
- `complete_job`
- `observe_wait_result`
- `release_job`
- `clear_job_member`
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
- `job_signal_scope`
- `job_resume_sends_sigcont`
- `job_requires_terminal_handoff`
- `pipeline_member_count`
- `jobs_backend_name`

Current semantics:

- `job_spec` carries the intended command, argument vector, and foreground/background intent
- `make_job_spec()` builds a reusable spec value for later launch or attach work
- `configure_job()` resets a handle into a configured-but-not-running state from a spec
- `attach_job()` records pid/process-group identity for an already launched job and establishes both process and process-group ownership expectations
- `attach_pipeline_members()` binds one handle to multiple tracked member pids for pipeline-style jobs
- `job_exit_result()`, `job_signal_result()`, `job_stop_result()`, and `job_continue_result()` build explicit wait outcomes for later launch or wait backends
- `observe_wait_result()` applies non-terminal and terminal wait state transitions to a tracked handle and now updates pipeline members too
- `complete_job()` now models terminal completion only and clears runtime cleanup obligations after exit or signal outcomes
- `release_job()` drops cleanup ownership while preserving runtime tracking metadata
- `job_is_configured()`, `job_is_running()`, `job_is_stopped()`, `job_is_finished()`, `job_needs_cleanup()`, and `job_owns_process_group()` expose the current stable lifecycle predicates
- `job_signal_scope()`, `job_resume_sends_sigcont()`, and `job_requires_terminal_handoff()` make signal and terminal assumptions explicit for future backends
- `job_handle` is now the explicit ownership point for a launched job group, and may track member-level pipeline state
- `job_result` now carries pid/process-group identity plus exited, signaled, stopped, and continued wait outcomes
- grouped pipeline jobs only finish once all tracked members have reached terminal outcomes
- reattaching pipeline members replaces the previous tracked member set cleanly
- group-scoped stop fanout preserves each tracked member pid in member-level results
- `jobs_backend_name()` currently reports the planned backend family and exists to stabilize the package surface early

## Build And Test

```bash
fpm test
```

Tracked examples:

- [job_lifecycle_demo.f90](example/job_lifecycle_demo.f90)
- [pipeline_tracking_demo.f90](example/pipeline_tracking_demo.f90)

## Supported Platforms

- macOS
- Linux

## Boundaries

- intended to stay independently versioned and releasable
- focused on reusable job-control mechanics first, not full shell policy
- should remain useful on its own even if future shells or supervisors build on top

## License

MIT
