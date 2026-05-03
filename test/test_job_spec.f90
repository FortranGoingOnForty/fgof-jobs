program test_job_spec
  use fgof_jobs, only : make_job_spec
  use fgof_jobs_types, only : job_spec
  implicit none

  type(job_spec) :: spec
  character(len=5) :: argv(2)

  argv = [character(len=5) :: "one  ", "two  "]
  spec = make_job_spec("sleep", argv, background=.true., new_process_group=.false.)

  if (.not. allocated(spec%command)) error stop "make_job_spec should allocate command text"
  if (spec%command /= "sleep") error stop "make_job_spec should preserve command text"
  if (.not. allocated(spec%argv)) error stop "make_job_spec should allocate argv when present"
  if (size(spec%argv) /= 2) error stop "make_job_spec should preserve argv length"
  if (spec%argv(1) /= "one  ") error stop "make_job_spec should preserve argv element content"
  if (.not. spec%background) error stop "make_job_spec should preserve background intent"
  if (spec%new_process_group) error stop "make_job_spec should preserve explicit process-group intent"
end program test_job_spec
