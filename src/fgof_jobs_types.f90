module fgof_jobs_types
  implicit none
  private

  type, public :: job_spec
    character(len=:), allocatable :: command
    character(len=:), allocatable :: argv(:)
    logical :: background = .false.
    logical :: new_process_group = .true.
  end type job_spec

  type, public :: job_result
    integer :: exit_code = 0
    integer :: signal = 0
    logical :: exited = .false.
    logical :: signaled = .false.
    logical :: stopped = .false.
    logical :: available = .false.
  end type job_result

  type, public :: job_handle
    type(job_spec) :: spec
    type(job_result) :: result
    integer :: pid = 0
    integer :: process_group = 0
    logical :: configured = .false.
    logical :: running = .false.
    logical :: finished = .false.
    logical :: background = .false.
    logical :: owns_process = .false.
    logical :: cleanup_needed = .false.
  end type job_handle

end module fgof_jobs_types
