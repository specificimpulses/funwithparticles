module timers
    implicit none
    integer time_ticks,fps_frames,total_frames
    real time_now,time_last,dt,dt_real,t_total,t_total_real,&
    dt_max,dt_min,fps_time,fps
    logical fps_print

contains

    subroutine init_timers()
        time_now = 0.0
        time_last = 0.0
        dt = 0.0
        dt_real = 0.0
        t_total = 0.0
        t_total_real = 0.0
        dt_max = 0.03  ! 20 updates per game second minimum
        dt_min = 0.0001 ! not really needed right now
        fps_time = 0.0
        fps_frames = 0
        total_frames = 0
    end subroutine init_timers

    subroutine update_timers()
        integer time_ticks_last,count_rate,count_max,dt_ticks
        time_ticks_last = time_ticks
        call system_clock(time_ticks,count_rate,count_max)
        dt_ticks = time_ticks - time_ticks_last
        dt_real = float(dt_ticks)/float(count_rate)
        dt = min(max(dt_real,dt_min),dt_max)
        t_total_real = t_total_real + dt_real
        t_total = t_total + dt
        time_last = time_now
        time_now = time_last + dt
        fps_time = fps_time + dt_real
        fps_frames = fps_frames + 1
        fps_print = .false.
        if(fps_time >= 5.0)then
          fps = float(fps_frames)/fps_time
          fps_time = 0.0
          fps_frames = 0
          fps_print = .true.
        endif
    end subroutine update_timers

end module timers
