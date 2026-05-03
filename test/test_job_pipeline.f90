program test_job_pipeline
  use fgof_jobs, only : &
    FGOF_JOBS_SIGNAL_SCOPE_GROUP, &
    FGOF_JOBS_SIGNAL_SCOPE_LEADER, &
    FGOF_JOBS_TERMINAL_HANDOFF_ALWAYS, &
    FGOF_JOBS_TERMINAL_HANDOFF_FOREGROUND, &
    attach_job, &
    attach_pipeline_members, &
    clear_job_handle, &
    complete_job, &
    configure_job, &
    job_continue_result, &
    job_exit_result, &
    job_is_finished, &
    job_is_running, &
    job_is_stopped, &
    job_needs_cleanup, &
    job_owns_process_group, &
    job_requires_terminal_handoff, &
    job_resume_sends_sigcont, &
    job_signal_scope, &
    job_stop_result, &
    make_job_spec, &
    observe_wait_result, &
    pipeline_member_count
  use fgof_jobs_types, only : job_handle, job_spec
  implicit none

  type(job_spec) :: spec
  type(job_handle) :: handle

  spec = make_job_spec("pipeline-head", signal_scope=FGOF_JOBS_SIGNAL_SCOPE_GROUP, &
                       terminal_handoff=FGOF_JOBS_TERMINAL_HANDOFF_FOREGROUND)
  handle = clear_job_handle()
  call configure_job(handle, spec)
  call attach_job(handle, 101)
  call attach_pipeline_members(handle, [101, 102, 103])

  if (pipeline_member_count(handle) /= 3) error stop "attach_pipeline_members should preserve member count"
  if (handle%members(2)%pid /= 102) error stop "attach_pipeline_members should preserve member pid ordering"
  if (.not. handle%members(3)%running) error stop "attached pipeline members should start in running state"
  if (job_signal_scope(handle) /= FGOF_JOBS_SIGNAL_SCOPE_GROUP) error stop "configured jobs should preserve signal scope"
  if (.not. job_owns_process_group(handle)) error stop "leader jobs should own their process group by default"
  if (.not. job_requires_terminal_handoff(handle)) error stop "foreground handoff policy should require terminal handoff"
  if (.not. job_resume_sends_sigcont(handle)) error stop "default resume policy should send SIGCONT"

  call observe_wait_result(handle, job_stop_result(20, pid=102, process_group=101))
  if (.not. job_is_stopped(handle)) error stop "group-scoped stop results should stop the whole pipeline"
  if (job_is_running(handle)) error stop "group-scoped stop results should clear running state"
  if (.not. handle%members(1)%stopped) error stop "group-scoped stop results should mark earlier members stopped"
  if (.not. handle%members(3)%stopped) error stop "group-scoped stop results should mark later members stopped"
  if (.not. job_needs_cleanup(handle)) error stop "stopped pipelines should still need cleanup"

  call observe_wait_result(handle, job_continue_result(pid=101, process_group=101))
  if (.not. job_is_running(handle)) error stop "group-scoped continue results should resume the pipeline"
  if (job_is_stopped(handle)) error stop "group-scoped continue results should clear stopped state"
  if (.not. handle%members(2)%running) error stop "group-scoped continue results should resume all members"

  call complete_job(handle, job_exit_result(0, pid=101, process_group=101))
  if (job_is_finished(handle)) error stop "one finished member should not finish the whole pipeline"
  if (.not. handle%members(1)%finished) error stop "terminal results should finish the matching member"
  if (handle%members(2)%finished) error stop "terminal results should not finish untouched members"
  if (.not. job_needs_cleanup(handle)) error stop "partially finished pipelines should still need cleanup"

  call observe_wait_result(handle, job_stop_result(20, pid=102, process_group=101))
  if (.not. handle%members(1)%finished) error stop "group stop should not reopen finished members"
  if (handle%members(1)%stopped) error stop "group stop should not mark finished members stopped"
  if (.not. handle%members(1)%result%exited) error stop "group stop should preserve finished member results"
  if (.not. handle%members(2)%stopped) error stop "group stop should still stop live members"
  if (.not. handle%members(3)%stopped) error stop "group stop should still stop later live members"

  call observe_wait_result(handle, job_continue_result(pid=101, process_group=101))
  if (handle%members(1)%running) error stop "group continue should not resume finished members"
  if (handle%members(1)%stopped) error stop "group continue should leave finished members terminal"
  if (.not. handle%members(2)%running) error stop "group continue should resume live members"
  if (.not. handle%members(3)%running) error stop "group continue should resume later live members"

  call complete_job(handle, job_exit_result(0, pid=102, process_group=101))
  call complete_job(handle, job_exit_result(0, pid=103, process_group=101))
  if (.not. job_is_finished(handle)) error stop "all finished members should finish the pipeline"
  if (job_is_running(handle)) error stop "fully finished pipelines should no longer run"
  if (job_needs_cleanup(handle)) error stop "fully finished pipelines should clear cleanup state"

  spec = make_job_spec("child-only", signal_scope=FGOF_JOBS_SIGNAL_SCOPE_LEADER, &
                       terminal_handoff=FGOF_JOBS_TERMINAL_HANDOFF_ALWAYS, resume_sends_sigcont=.false.)
  handle = clear_job_handle()
  call configure_job(handle, spec)
  call attach_job(handle, 201, process_group=200, owns_process=.true., owns_process_group=.false.)
  call attach_pipeline_members(handle, [201, 202])

  if (job_owns_process_group(handle)) error stop "explicit non-owning process-group tracking should be preserved"
  if (.not. job_requires_terminal_handoff(handle)) error stop "always handoff policy should require terminal handoff"
  if (job_resume_sends_sigcont(handle)) error stop "explicit resume policy should be preserved"

  call observe_wait_result(handle, job_stop_result(19, pid=202, process_group=200))
  if (.not. handle%members(2)%stopped) error stop "leader-scoped stop results should still update the matching member"
  if (handle%members(1)%stopped) error stop "leader-scoped stop results should not stop unrelated members"
end program test_job_pipeline
