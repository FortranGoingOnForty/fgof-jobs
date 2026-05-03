program test_scaffold
  use fgof_jobs, only : &
    clear_job_handle, &
    clear_job_result, &
    clear_job_spec, &
    jobs_backend_name
  use fgof_jobs_types, only : job_handle, job_result, job_spec
  implicit none

  type(job_spec) :: spec
  type(job_handle) :: handle
  type(job_result) :: result_value

  spec = clear_job_spec()
  if (allocated(spec%command)) error stop "job spec should not allocate command by default"
  if (allocated(spec%argv)) error stop "job spec should not allocate argv by default"
  if (spec%background) error stop "job spec should start in foreground mode"
  if (.not. spec%new_process_group) error stop "job spec should default to a new process group"

  handle = clear_job_handle()
  if (allocated(handle%spec%command)) error stop "job handle should clear embedded spec command"
  if (allocated(handle%spec%argv)) error stop "job handle should clear embedded spec argv"
  if (handle%pid /= 0) error stop "job handle should start with pid zero"
  if (handle%process_group /= 0) error stop "job handle should start with process group zero"
  if (handle%configured) error stop "job handle should not start configured"
  if (handle%running) error stop "job handle should not start running"
  if (handle%stopped) error stop "job handle should not start stopped"
  if (handle%finished) error stop "job handle should not start finished"
  if (handle%background) error stop "job handle should not start as background"
  if (handle%owns_process) error stop "job handle should not own a process by default"
  if (handle%owns_process_group) error stop "job handle should not own a process group by default"
  if (handle%cleanup_needed) error stop "job handle should not need cleanup by default"

  result_value = clear_job_result()
  if (result_value%pid /= 0) error stop "job result should start with pid zero"
  if (result_value%process_group /= 0) error stop "job result should start with process group zero"
  if (result_value%exit_code /= 0) error stop "job result should start with exit code zero"
  if (result_value%signal /= 0) error stop "job result should start with signal zero"
  if (result_value%exited) error stop "job result should not start exited"
  if (result_value%signaled) error stop "job result should not start signaled"
  if (result_value%stopped) error stop "job result should not start stopped"
  if (result_value%continued) error stop "job result should not start continued"
  if (result_value%available) error stop "job result should not start available"

  if (jobs_backend_name() /= "posix") error stop "jobs backend should report the planned POSIX-first backend"
end program test_scaffold
