program test_job_waits
  use fgof_jobs, only : &
    attach_job, &
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
    job_signal_result, &
    job_stop_result, &
    make_job_spec, &
    observe_wait_result
  use fgof_jobs_types, only : job_handle, job_result, job_spec
  implicit none

  type(job_spec) :: spec
  type(job_handle) :: handle
  type(job_result) :: result_value

  spec = make_job_spec("shell-job")
  handle = clear_job_handle()
  call configure_job(handle, spec)
  call attach_job(handle, 41)
  if (.not. job_owns_process_group(handle)) error stop "new process-group jobs should own their process group by default"
  if (.not. job_needs_cleanup(handle)) error stop "attached jobs should start needing cleanup"

  result_value = job_stop_result(19)
  call observe_wait_result(handle, result_value)
  if (job_is_running(handle)) error stop "stop results should clear running state"
  if (.not. job_is_stopped(handle)) error stop "stop results should mark the handle stopped"
  if (job_is_finished(handle)) error stop "stop results should not mark the handle finished"
  if (.not. job_needs_cleanup(handle)) error stop "stopped jobs should still need later cleanup or wait handling"
  if (handle%result%pid /= 41) error stop "wait results without pid should inherit the attached pid"
  if (handle%result%process_group /= 41) error stop "wait results without process group should inherit the attached group"

  result_value = job_continue_result()
  call observe_wait_result(handle, result_value)
  if (.not. job_is_running(handle)) error stop "continue results should resume running state"
  if (job_is_stopped(handle)) error stop "continue results should clear stopped state"
  if (job_is_finished(handle)) error stop "continue results should not mark the handle finished"
  if (.not. job_needs_cleanup(handle)) error stop "continued jobs should still need later cleanup or wait handling"

  result_value = job_exit_result(3)
  call complete_job(handle, result_value)
  if (job_is_running(handle)) error stop "exit completion should clear running state"
  if (job_is_stopped(handle)) error stop "exit completion should clear stopped state"
  if (.not. job_is_finished(handle)) error stop "exit completion should mark the handle finished"
  if (job_needs_cleanup(handle)) error stop "terminal exit completion should clear cleanup state"
  if (.not. handle%result%exited) error stop "exit completion should preserve exit classification"
  if (handle%result%exit_code /= 3) error stop "exit completion should preserve exit code"

  handle = clear_job_handle()
  spec = make_job_spec("pipeline-child", new_process_group=.false.)
  call configure_job(handle, spec)
  call attach_job(handle, 80, process_group=12, owns_process=.true.)
  if (job_owns_process_group(handle)) error stop "non-leader jobs should not own process groups by default"
  if (.not. job_needs_cleanup(handle)) error stop "process ownership alone should still require cleanup"

  result_value = job_signal_result(15, pid=80, process_group=12)
  call complete_job(handle, result_value)
  if (.not. job_is_finished(handle)) error stop "signal completion should mark the handle finished"
  if (.not. handle%result%signaled) error stop "signal completion should preserve signal classification"
  if (handle%result%signal /= 15) error stop "signal completion should preserve signal values"
end program test_job_waits
