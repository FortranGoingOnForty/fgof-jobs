module fgof_jobs
  use fgof_jobs_types, only : job_handle, job_result, job_spec
  implicit none
  private

  character(len=*), parameter :: FGOF_JOBS_BACKEND_NONE = "none"
  character(len=*), parameter :: FGOF_JOBS_BACKEND_POSIX = "posix"

  public :: &
    clear_job_handle, &
    clear_job_result, &
    clear_job_spec, &
    job_handle, &
    job_result, &
    job_spec, &
    jobs_backend_name

contains

  function clear_job_spec() result(spec)
    type(job_spec) :: spec

    spec%background = .false.
    spec%new_process_group = .true.
  end function clear_job_spec

  function clear_job_handle() result(handle)
    type(job_handle) :: handle

    handle%pid = 0
    handle%process_group = 0
    handle%running = .false.
    handle%background = .false.
  end function clear_job_handle

  function clear_job_result() result(result_value)
    type(job_result) :: result_value

    result_value%exit_code = 0
    result_value%signal = 0
    result_value%exited = .false.
    result_value%signaled = .false.
    result_value%stopped = .false.
  end function clear_job_result

  function jobs_backend_name() result(name)
    character(len=:), allocatable :: name

    name = FGOF_JOBS_BACKEND_POSIX
  end function jobs_backend_name

end module fgof_jobs
