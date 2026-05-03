module fgof_jobs
  use fgof_jobs_types, only : job_handle, job_member, job_result, job_spec
  implicit none
  private

  character(len=*), parameter :: FGOF_JOBS_BACKEND_NONE = "none"
  character(len=*), parameter :: FGOF_JOBS_BACKEND_POSIX = "posix"
  integer, parameter :: FGOF_JOBS_SIGNAL_SCOPE_NONE = 0
  integer, parameter :: FGOF_JOBS_SIGNAL_SCOPE_LEADER = 1
  integer, parameter :: FGOF_JOBS_SIGNAL_SCOPE_GROUP = 2
  integer, parameter :: FGOF_JOBS_TERMINAL_HANDOFF_NEVER = 0
  integer, parameter :: FGOF_JOBS_TERMINAL_HANDOFF_FOREGROUND = 1
  integer, parameter :: FGOF_JOBS_TERMINAL_HANDOFF_ALWAYS = 2

  public :: &
    attach_job, &
    attach_pipeline_members, &
    clear_job_handle, &
    clear_job_member, &
    clear_job_result, &
    clear_job_spec, &
    complete_job, &
    configure_job, &
    FGOF_JOBS_SIGNAL_SCOPE_GROUP, &
    FGOF_JOBS_SIGNAL_SCOPE_LEADER, &
    FGOF_JOBS_SIGNAL_SCOPE_NONE, &
    FGOF_JOBS_TERMINAL_HANDOFF_ALWAYS, &
    FGOF_JOBS_TERMINAL_HANDOFF_FOREGROUND, &
    FGOF_JOBS_TERMINAL_HANDOFF_NEVER, &
    job_continue_result, &
    job_exit_result, &
    job_handle, &
    job_is_configured, &
    job_is_finished, &
    job_is_running, &
    job_is_stopped, &
    job_member, &
    job_needs_cleanup, &
    job_owns_process_group, &
    job_requires_terminal_handoff, &
    job_result, &
    job_resume_sends_sigcont, &
    job_signal_result, &
    job_signal_scope, &
    job_spec, &
    job_stop_result, &
    jobs_backend_name, &
    make_job_spec, &
    observe_wait_result, &
    pipeline_member_count, &
    release_job

contains

  function clear_job_spec() result(spec)
    type(job_spec) :: spec

    spec%background = .false.
    spec%new_process_group = .true.
    spec%signal_scope = FGOF_JOBS_SIGNAL_SCOPE_GROUP
    spec%terminal_handoff = FGOF_JOBS_TERMINAL_HANDOFF_FOREGROUND
    spec%resume_sends_sigcont = .true.
  end function clear_job_spec

  function clear_job_handle() result(handle)
    type(job_handle) :: handle

    handle%spec = clear_job_spec()
    handle%signal_scope = FGOF_JOBS_SIGNAL_SCOPE_GROUP
    handle%terminal_handoff = FGOF_JOBS_TERMINAL_HANDOFF_FOREGROUND
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
    handle%resume_sends_sigcont = .true.
  end function clear_job_handle

  function clear_job_member() result(member)
    type(job_member) :: member

    member%pid = 0
    member%running = .false.
    member%stopped = .false.
    member%finished = .false.
    member%result = clear_job_result()
  end function clear_job_member

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

  function make_job_spec(command, argv, background, new_process_group, signal_scope, terminal_handoff, &
                         resume_sends_sigcont) result(spec)
    character(len=*), intent(in) :: command
    character(len=*), intent(in), optional :: argv(:)
    logical, intent(in), optional :: background
    logical, intent(in), optional :: new_process_group
    integer, intent(in), optional :: signal_scope
    integer, intent(in), optional :: terminal_handoff
    logical, intent(in), optional :: resume_sends_sigcont
    type(job_spec) :: spec

    spec = clear_job_spec()

    if (len_trim(command) > 0) spec%command = trim(command)
    if (present(argv)) spec%argv = argv
    if (present(background)) spec%background = background
    if (present(new_process_group)) spec%new_process_group = new_process_group
    if (present(signal_scope)) spec%signal_scope = signal_scope
    if (present(terminal_handoff)) spec%terminal_handoff = terminal_handoff
    if (present(resume_sends_sigcont)) spec%resume_sends_sigcont = resume_sends_sigcont
  end function make_job_spec

  subroutine configure_job(handle, spec)
    type(job_handle), intent(inout) :: handle
    type(job_spec), intent(in) :: spec

    handle = clear_job_handle()
    handle%spec = spec
    handle%configured = allocated(spec%command)
    handle%background = spec%background
    handle%signal_scope = spec%signal_scope
    handle%terminal_handoff = spec%terminal_handoff
    handle%resume_sends_sigcont = spec%resume_sends_sigcont
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
    call reset_member_runtime(handle)
  end subroutine attach_job

  subroutine attach_pipeline_members(handle, pids)
    type(job_handle), intent(inout) :: handle
    integer, intent(in) :: pids(:)
    integer :: index_value

    if (.not. handle%configured) return
    if (size(pids) <= 0) return
    if (any(pids <= 0)) return

    allocate(handle%members(size(pids)))
    do index_value = 1, size(pids)
      handle%members(index_value) = clear_job_member()
      handle%members(index_value)%pid = pids(index_value)
      handle%members(index_value)%running = handle%running
    end do

    if (handle%pid <= 0) handle%pid = pids(1)
    if (handle%process_group <= 0) handle%process_group = handle%pid
    if (handle%owns_process_group) handle%cleanup_needed = .true.
  end subroutine attach_pipeline_members

  subroutine complete_job(handle, result_value)
    type(job_handle), intent(inout) :: handle
    type(job_result), intent(in) :: result_value

    if (result_value%stopped .or. result_value%continued) then
      return
    end if

    call observe_wait_result(handle, result_value)
  end subroutine complete_job

  subroutine observe_wait_result(handle, result_value)
    type(job_handle), intent(inout) :: handle
    type(job_result), intent(in) :: result_value
    integer :: member_index

    handle%result = result_value
    handle%result%available = result_value%available .or. result_value%exited .or. &
                              result_value%signaled .or. result_value%stopped .or. result_value%continued

    if (handle%result%pid <= 0) handle%result%pid = handle%pid
    if (handle%result%process_group <= 0) handle%result%process_group = handle%process_group

    member_index = member_index_for_pid(handle, handle%result%pid)

    if (handle%result%continued) then
      call apply_continue_state(handle, member_index)
      call recompute_handle_state(handle)
      return
    end if

    if (handle%result%stopped) then
      call apply_stop_state(handle, member_index, handle%result)
      call recompute_handle_state(handle)
      return
    end if

    if (handle%result%exited .or. handle%result%signaled) then
      call apply_terminal_state(handle, member_index, handle%result)
      call recompute_handle_state(handle)
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

  integer function job_signal_scope(handle) result(scope)
    type(job_handle), intent(in) :: handle

    scope = handle%signal_scope
  end function job_signal_scope

  logical function job_resume_sends_sigcont(handle) result(sends_sigcont)
    type(job_handle), intent(in) :: handle

    sends_sigcont = handle%resume_sends_sigcont
  end function job_resume_sends_sigcont

  logical function job_requires_terminal_handoff(handle) result(requires_handoff)
    type(job_handle), intent(in) :: handle

    select case (handle%terminal_handoff)
    case (FGOF_JOBS_TERMINAL_HANDOFF_NEVER)
      requires_handoff = .false.
    case (FGOF_JOBS_TERMINAL_HANDOFF_ALWAYS)
      requires_handoff = .true.
    case default
      requires_handoff = .not. handle%background
    end select
  end function job_requires_terminal_handoff

  integer function pipeline_member_count(handle) result(count)
    type(job_handle), intent(in) :: handle

    if (.not. allocated(handle%members)) then
      count = 0
      return
    end if

    count = size(handle%members)
  end function pipeline_member_count

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

  subroutine reset_member_runtime(handle)
    type(job_handle), intent(inout) :: handle
    integer :: index_value

    if (.not. allocated(handle%members)) return

    do index_value = 1, size(handle%members)
      handle%members(index_value)%running = handle%running
      handle%members(index_value)%stopped = .false.
      handle%members(index_value)%finished = .false.
      handle%members(index_value)%result = clear_job_result()
    end do
  end subroutine reset_member_runtime

  integer function member_index_for_pid(handle, pid) result(index_value)
    type(job_handle), intent(in) :: handle
    integer, intent(in) :: pid
    integer :: scan_index

    index_value = 0
    if (.not. allocated(handle%members)) return
    if (pid <= 0) return

    do scan_index = 1, size(handle%members)
      if (handle%members(scan_index)%pid == pid) then
        index_value = scan_index
        return
      end if
    end do
  end function member_index_for_pid

  subroutine apply_continue_state(handle, member_index)
    type(job_handle), intent(inout) :: handle
    integer, intent(in) :: member_index
    integer :: index_value

    if (allocated(handle%members)) then
      if (handle%signal_scope == FGOF_JOBS_SIGNAL_SCOPE_GROUP) then
        do index_value = 1, size(handle%members)
          handle%members(index_value)%running = .true.
          handle%members(index_value)%stopped = .false.
        end do
      else if (member_index > 0) then
        handle%members(member_index)%running = .true.
        handle%members(member_index)%stopped = .false.
      end if
    end if
  end subroutine apply_continue_state

  subroutine apply_stop_state(handle, member_index, result_value)
    type(job_handle), intent(inout) :: handle
    integer, intent(in) :: member_index
    type(job_result), intent(in) :: result_value
    integer :: index_value

    if (allocated(handle%members)) then
      if (handle%signal_scope == FGOF_JOBS_SIGNAL_SCOPE_GROUP) then
        do index_value = 1, size(handle%members)
          handle%members(index_value)%running = .false.
          handle%members(index_value)%stopped = .true.
          handle%members(index_value)%result = result_value
          if (handle%members(index_value)%result%pid <= 0) handle%members(index_value)%result%pid = handle%members(index_value)%pid
          if (handle%members(index_value)%result%process_group <= 0) handle%members(index_value)%result%process_group = handle%process_group
        end do
      else if (member_index > 0) then
        handle%members(member_index)%running = .false.
        handle%members(member_index)%stopped = .true.
        handle%members(member_index)%result = result_value
        if (handle%members(member_index)%result%pid <= 0) handle%members(member_index)%result%pid = handle%members(member_index)%pid
        if (handle%members(member_index)%result%process_group <= 0) handle%members(member_index)%result%process_group = handle%process_group
      end if
    end if
  end subroutine apply_stop_state

  subroutine apply_terminal_state(handle, member_index, result_value)
    type(job_handle), intent(inout) :: handle
    integer, intent(in) :: member_index
    type(job_result), intent(in) :: result_value

    if (allocated(handle%members)) then
      if (member_index > 0) then
        handle%members(member_index)%running = .false.
        handle%members(member_index)%stopped = .false.
        handle%members(member_index)%finished = .true.
        handle%members(member_index)%result = result_value
        if (handle%members(member_index)%result%pid <= 0) handle%members(member_index)%result%pid = handle%members(member_index)%pid
        if (handle%members(member_index)%result%process_group <= 0) then
          handle%members(member_index)%result%process_group = handle%process_group
        end if
      end if
    end if
  end subroutine apply_terminal_state

  subroutine recompute_handle_state(handle)
    type(job_handle), intent(inout) :: handle

    if (.not. allocated(handle%members)) then
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
      end if
      return
    end if

    handle%running = any(handle%members%running)
    handle%stopped = (.not. handle%running) .and. any(handle%members%stopped)
    handle%finished = all(handle%members%finished)
    if (handle%finished) then
      handle%cleanup_needed = .false.
    else
      handle%cleanup_needed = handle%owns_process .or. handle%owns_process_group
    end if
  end subroutine recompute_handle_state

  function jobs_backend_name() result(name)
    character(len=:), allocatable :: name

    name = FGOF_JOBS_BACKEND_POSIX
  end function jobs_backend_name

end module fgof_jobs
