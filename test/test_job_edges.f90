program test_job_edges
  use fgof_jobs, only : &
    FGOF_JOBS_SIGNAL_SCOPE_GROUP, &
    attach_job, &
    attach_pipeline_members, &
    clear_job_handle, &
    configure_job, &
    job_stop_result, &
    make_job_spec, &
    observe_wait_result, &
    pipeline_member_count, &
    release_job
  use fgof_jobs_types, only : job_handle, job_spec
  implicit none

  type(job_spec) :: spec
  type(job_handle) :: handle

  spec = make_job_spec("pipeline-head", signal_scope=FGOF_JOBS_SIGNAL_SCOPE_GROUP)
  handle = clear_job_handle()
  call configure_job(handle, spec)
  call attach_job(handle, 301)
  call attach_pipeline_members(handle, [301, 302, 303])
  call attach_pipeline_members(handle, [301, 304])

  if (pipeline_member_count(handle) /= 2) then
    error stop "reattaching pipeline members should replace the old member set"
  end if
  if (handle%members(2)%pid /= 304) then
    error stop "reattaching pipeline members should preserve the new member ordering"
  end if

  call observe_wait_result(handle, job_stop_result(19, pid=304, process_group=301))
  if (handle%members(1)%result%pid /= 301) then
    error stop "group stop fanout should preserve each member pid"
  end if
  if (handle%members(2)%result%pid /= 304) then
    error stop "group stop fanout should keep the matching member pid"
  end if
  if (handle%members(1)%result%process_group /= 301) then
    error stop "group stop fanout should preserve the shared process group"
  end if

  call release_job(handle)
  call release_job(handle)
  if (handle%cleanup_needed) then
    error stop "release_job should stay idempotent after repeated calls"
  end if
end program test_job_edges
