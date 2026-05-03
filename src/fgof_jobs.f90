module fgof_jobs
  use fgof_jobs_types, only : job_handle, job_result, job_spec
  implicit none
  private

  character(len=*), parameter :: FGOF_JOBS_BACKEND_NONE = "none"
  character(len=*), parameter :: FGOF_JOBS_BACKEND_POSIX = "posix"

  public :: &
    attach_job, &
    clear_job_handle, &
    clear_job_result, &
    clear_job_spec, &
    complete_job, &
    configure_job, &
    job_continue_result, &
    job_exit_result, &
    job_handle, &
    job_is_configured, &
    job_is_finished, &
    job_is_running, &
    job_is_stopped, &
    job_needs_cleanup, &
    job_owns_process_group, &
    job_result, &
    job_signal_result, &
    job_spec, &
    job_stop_result, &
    jobs_backend_name, &
    make_job_spec, &
    observe_wait_result, &
    release_job

contains

  function clear_job_spec() result(spec)
    type(job_spec) :: spec

    spec%background = .false.
    spec%new_process_group = .true.
  end function clear_job_spec

  function clear_job_handle() result(handle)
    type(job_handle) :: handle

    handle%spec = clear_job_spec()
    handle%result = clear_job_result()
    handle%pid = 0
    handle%process_group = 0
    handle%configured = .false.
    handle%running = .false.
    handle%stopped = .false.
    handle%finished = .false.
    handle%background = .false.
    handle%owns_process = .false.
    handle%owns_process_group = .false.
    handle%cleanup_needed = .false.
  end function clear_job_handle

  function clear_job_result() result(result_value)
    type(job_result) :: result_value

    result_value%pid = 0
    result_value%process_group = 0
    result_value%exit_code = 0
    result_value%signal = 0
    result_value%exited = .false.
    result_value%signaled = .false.
    result_value%stopped = .false.
    result_value%continued = .false.
    result_value%available = .false.
  end function clear_job_result

  function make_job_spec(command, argv, background, new_process_group) result(spec)
    character(len=*), intent(in) :: command
    character(len=*), intent(in), optional :: argv(:)
    logical, intent(in), optional :: background
    logical, intent(in), optional :: new_process_group
    type(job_spec) :: spec

    spec = clear_job_spec()

    if (len_trim(command) > 0) spec%command = trim(command)
    if (present(argv)) spec%argv = argv
    if (present(background)) spec%background = background
    if (present(new_process_group)) spec%new_process_group = new_process_group
  end function make_job_spec

  subroutine configure_job(handle, spec)
    type(job_handle), intent(inout) :: handle
    type(job_spec), intent(in) :: spec

    handle = clear_job_handle()
    handle%spec = spec
    handle%configured = allocated(spec%command)
    handle%background = spec%background
  end subroutine configure_job

  subroutine attach_job(handle, pid, process_group, owns_process, owns_process_group)
    type(job_handle), intent(inout) :: handle
    integer, intent(in) :: pid
    integer, intent(in), optional :: process_group
    logical, intent(in), optional :: owns_process
    logical, intent(in), optional :: owns_process_group

    if (.not. handle%configured) return
    if (pid <= 0) return

    handle%pid = pid
    if (present(process_group)) then
      if (process_group > 0) then
        handle%process_group = process_group
      else
        handle%process_group = pid
      end if
    else
      handle%process_group = pid
    end if

    if (present(owns_process)) then
      handle%owns_process = owns_process
    else
      handle%owns_process = .true.
    end if

    if (present(owns_process_group)) then
      handle%owns_process_group = owns_process_group
    else
      handle%owns_process_group = handle%owns_process .and. handle%spec%new_process_group .and. &
                                  handle%process_group == pid
    end if

    handle%running = .true.
    handle%stopped = .false.
    handle%finished = .false.
    handle%cleanup_needed = handle%owns_process .or. handle%owns_process_group
    handle%result = clear_job_result()
  end subroutine attach_job

  subroutine complete_job(handle, result_value)
    type(job_handle), intent(inout) :: handle
    type(job_result), intent(in) :: result_value

    if (result_value%stopped .or. result_value%continued) then
      return
    end if

    call observe_wait_result(handle, result_value)
    handle%finished = handle%result%exited .or. handle%result%signaled
    handle%cleanup_needed = .false.
  end subroutine complete_job

  subroutine observe_wait_result(handle, result_value)
    type(job_handle), intent(inout) :: handle
    type(job_result), intent(in) :: result_value

    handle%result = result_value
    handle%result%available = result_value%available .or. result_value%exited .or. &
                              result_value%signaled .or. result_value%stopped .or. result_value%continued

    if (handle%result%pid <= 0) handle%result%pid = handle%pid
    if (handle%result%process_group <= 0) handle%result%process_group = handle%process_group

    if (handle%result%continued) then
      handle%running = .true.
      handle%stopped = .false.
      handle%finished = .false.
      handle%cleanup_needed = handle%owns_process .or. handle%owns_process_group
      return
    end if

    if (handle%result%stopped) then
      handle%running = .false.
      handle%stopped = .true.
      handle%finished = .false.
      handle%cleanup_needed = handle%owns_process .or. handle%owns_process_group
      return
    end if

    if (handle%result%exited .or. handle%result%signaled) then
      handle%running = .false.
      handle%stopped = .false.
      handle%finished = .true.
      handle%cleanup_needed = .false.
      return
    end if
  end subroutine observe_wait_result

  subroutine release_job(handle)
    type(job_handle), intent(inout) :: handle

    handle%owns_process = .false.
    handle%owns_process_group = .false.
    handle%cleanup_needed = .false.
  end subroutine release_job

  logical function job_is_configured(handle) result(configured)
    type(job_handle), intent(in) :: handle

    configured = handle%configured
  end function job_is_configured

  logical function job_is_running(handle) result(running)
    type(job_handle), intent(in) :: handle

    running = handle%configured .and. handle%running
  end function job_is_running

  logical function job_is_stopped(handle) result(stopped)
    type(job_handle), intent(in) :: handle

    stopped = handle%configured .and. handle%stopped
  end function job_is_stopped

  logical function job_is_finished(handle) result(finished)
    type(job_handle), intent(in) :: handle

    finished = handle%finished
  end function job_is_finished

  logical function job_needs_cleanup(handle) result(needs_cleanup)
    type(job_handle), intent(in) :: handle

    needs_cleanup = handle%cleanup_needed
  end function job_needs_cleanup

  logical function job_owns_process_group(handle) result(owns_group)
    type(job_handle), intent(in) :: handle

    owns_group = handle%owns_process_group
  end function job_owns_process_group

  function job_exit_result(exit_code, pid, process_group) result(result_value)
    integer, intent(in) :: exit_code
    integer, intent(in), optional :: pid
    integer, intent(in), optional :: process_group
    type(job_result) :: result_value

    result_value = clear_job_result()
    if (present(pid)) result_value%pid = pid
    if (present(process_group)) result_value%process_group = process_group
    result_value%exit_code = exit_code
    result_value%exited = .true.
    result_value%available = .true.
  end function job_exit_result

  function job_signal_result(signal, pid, process_group) result(result_value)
    integer, intent(in) :: signal
    integer, intent(in), optional :: pid
    integer, intent(in), optional :: process_group
    type(job_result) :: result_value

    result_value = clear_job_result()
    if (present(pid)) result_value%pid = pid
    if (present(process_group)) result_value%process_group = process_group
    result_value%signal = signal
    result_value%signaled = .true.
    result_value%available = .true.
  end function job_signal_result

  function job_stop_result(signal, pid, process_group) result(result_value)
    integer, intent(in) :: signal
    integer, intent(in), optional :: pid
    integer, intent(in), optional :: process_group
    type(job_result) :: result_value

    result_value = clear_job_result()
    if (present(pid)) result_value%pid = pid
    if (present(process_group)) result_value%process_group = process_group
    result_value%signal = signal
    result_value%stopped = .true.
    result_value%available = .true.
  end function job_stop_result

  function job_continue_result(pid, process_group) result(result_value)
    integer, intent(in), optional :: pid
    integer, intent(in), optional :: process_group
    type(job_result) :: result_value

    result_value = clear_job_result()
    if (present(pid)) result_value%pid = pid
    if (present(process_group)) result_value%process_group = process_group
    result_value%continued = .true.
    result_value%available = .true.
  end function job_continue_result

  function jobs_backend_name() result(name)
    character(len=:), allocatable :: name

    name = FGOF_JOBS_BACKEND_POSIX
  end function jobs_backend_name

end module fgof_jobs
