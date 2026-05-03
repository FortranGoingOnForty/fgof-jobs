program pipeline_tracking_demo
  use fgof_jobs, only : &
    FGOF_JOBS_SIGNAL_SCOPE_GROUP, &
    attach_job, &
    attach_pipeline_members, &
    complete_job, &
    configure_job, &
    job_exit_result, &
    job_is_finished, &
    job_stop_result, &
    make_job_spec, &
    observe_wait_result, &
    pipeline_member_count
  use fgof_jobs_types, only : job_handle, job_spec
  implicit none

  type(job_spec) :: spec
  type(job_handle) :: handle

  spec = make_job_spec("pipeline-head", signal_scope=FGOF_JOBS_SIGNAL_SCOPE_GROUP)
  call configure_job(handle, spec)
  call attach_job(handle, 101)
  call attach_pipeline_members(handle, [101, 102, 103])
  call observe_wait_result(handle, job_stop_result(20, pid=102, process_group=101))
  call complete_job(handle, job_exit_result(0, pid=101, process_group=101))
  call complete_job(handle, job_exit_result(0, pid=102, process_group=101))
  call complete_job(handle, job_exit_result(0, pid=103, process_group=101))

  write (*, '(a,i0)') "members=", pipeline_member_count(handle)
  write (*, '(a,l1)') "finished=", job_is_finished(handle)
end program pipeline_tracking_demo
