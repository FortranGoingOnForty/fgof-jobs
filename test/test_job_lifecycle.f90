program test_job_lifecycle
  use fgof_jobs, only : &
    attach_job, &
    clear_job_handle, &
    clear_job_result, &
    complete_job, &
    configure_job, &
    job_is_configured, &
    job_is_finished, &
    job_is_running, &
    job_needs_cleanup, &
    make_job_spec, &
    release_job
  use fgof_jobs_types, only : job_handle, job_result, job_spec
  implicit none

  type(job_spec) :: spec
  type(job_handle) :: handle
  type(job_result) :: result_value

  spec = make_job_spec("worker", background=.true.)
  handle = clear_job_handle()

  call configure_job(handle, spec)
  if (.not. job_is_configured(handle)) error stop "configure_job should mark the handle configured"
  if (.not. handle%background) error stop "configure_job should copy background intent"
  if (job_is_running(handle)) error stop "configure_job should not start a job running"
  if (handle%pid /= 0) error stop "configure_job should keep pid clear before attach"

  call attach_job(handle, 42)
  if (.not. job_is_running(handle)) error stop "attach_job should mark a configured job running"
  if (handle%pid /= 42) error stop "attach_job should record pid"
  if (handle%process_group /= 42) error stop "attach_job should default process group to pid"
  if (.not. handle%owns_process) error stop "attach_job should own the process by default"
  if (.not. job_needs_cleanup(handle)) error stop "attach_job should request cleanup while owned and running"
  if (job_is_finished(handle)) error stop "attach_job should not mark the job finished"

  call release_job(handle)
  if (handle%owns_process) error stop "release_job should relinquish process ownership"
  if (job_needs_cleanup(handle)) error stop "release_job should clear cleanup obligations"
  if (.not. job_is_running(handle)) error stop "release_job should not stop runtime tracking"

  handle = clear_job_handle()
  call configure_job(handle, spec)
  call attach_job(handle, 99, process_group=17, owns_process=.false.)
  if (handle%process_group /= 17) error stop "attach_job should preserve explicit process-group values"
  if (handle%owns_process) error stop "attach_job should accept explicit non-owning tracking"
  if (job_needs_cleanup(handle)) error stop "non-owning tracking should not request cleanup"

  result_value = clear_job_result()
  result_value%exit_code = 7
  result_value%exited = .true.
  call complete_job(handle, result_value)
  if (job_is_running(handle)) error stop "complete_job should stop runtime tracking"
  if (.not. job_is_finished(handle)) error stop "complete_job should mark the job finished when a result is available"
  if (job_needs_cleanup(handle)) error stop "complete_job should clear cleanup obligations"
  if (.not. handle%result%available) error stop "complete_job should mark the embedded result available"
  if (handle%result%exit_code /= 7) error stop "complete_job should preserve result payloads"
end program test_job_lifecycle
