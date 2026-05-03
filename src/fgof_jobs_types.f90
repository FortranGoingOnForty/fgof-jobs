module fgof_jobs_types
  implicit none
  private

  type, public :: job_spec
    character(len=:), allocatable :: command
    character(len=:), allocatable :: argv(:)
    logical :: background = .false.
    logical :: new_process_group = .true.
  end type job_spec

  type, public :: job_handle
    integer :: pid = 0
    integer :: process_group = 0
    logical :: running = .false.
    logical :: background = .false.
  end type job_handle

  type, public :: job_result
    integer :: exit_code = 0
    integer :: signal = 0
    logical :: exited = .false.
    logical :: signaled = .false.
    logical :: stopped = .false.
  end type job_result

end module fgof_jobs_types
