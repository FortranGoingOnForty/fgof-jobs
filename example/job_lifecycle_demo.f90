program job_lifecycle_demo
  use fgof_jobs, only : &
    attach_job, &
    complete_job, &
    configure_job, &
    job_exit_result, &
    job_is_finished, &
    job_needs_cleanup, &
    make_job_spec
  use fgof_jobs_types, only : job_handle, job_spec
  implicit none

  type(job_spec) :: spec
  type(job_handle) :: handle

  spec = make_job_spec("worker")
  call configure_job(handle, spec)
  call attach_job(handle, 41)
  call complete_job(handle, job_exit_result(0, pid=41, process_group=41))

  write (*, '(a,l1)') "finished=", job_is_finished(handle)
  write (*, '(a,l1)') "cleanup=", job_needs_cleanup(handle)
end program job_lifecycle_demo
