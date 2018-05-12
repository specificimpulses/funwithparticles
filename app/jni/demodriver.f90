program main
  use ISO_C_BINDING
end program

! main event sub-loop
subroutine dust_engine_run() bind(c)
  use dustengine
  use android_fortran
  call update_timers()  
  framecount=framecount+1.0
  engine_timer(1) = time1
  ticks_out = engine_timer(1) - engine_timer(2)
  !write(10,*)"calling fortran_process_events..."
  !flush(10)
  call fortran_process_events(fortran_app)
  call glclearbuffer()
  call touch_events()
  if(.not.menu_on)call rundemo()
  !call gl_draw_ui()
  if(drawtext)call pull_text(5.0)
  call drawarrays()
  call draw_ui_overlay()
  call system_clock(engine_timer(2),count_rate,count_max)
  ticks_in = engine_timer(2) - engine_timer(1)
  button_delay = button_delay - dt
  if(ui_delay < 0.0)then
    if(menu_on)menu_on = .false.
    ui_delay = 0.0
  elseif(ui_delay > 0.0)then
    !write(10,*)'ui_delay = ',ui_delay
    !flush(10)
    ui_delay = ui_delay - dt
  endif
end subroutine dust_engine_run

! get sensor data and modify the engine state
subroutine dust_com_sensors(my_accelx,my_accely,my_accelz) bind(c)
  use dustengine
  real, intent(in) :: my_accelx, my_accely, my_accelz
  accelx = my_accelx
  accely = my_accely
  accelz = my_accelz
end subroutine

! get key presses
subroutine dust_com_key(my_Code,my_Action) bind(c)
  use dustengine
  integer, intent(in) :: my_Code,my_Action
  key_num = my_Code
  !write(10,*)"my_Code = ",my_Code," my_Action = ",my_Action
  !flush(10)
  if(my_Code == 82 .and. my_Action == 1)then
    call menu_toggle()
    if(start_message)then
      textdropped = 0
      start_message = .false.
    endif
  endif
  if(my_Code == 4 .and. my_Action == 1)call shutdown()
end subroutine dust_com_key

subroutine set_android_app(my_app)bind(c)
  use dustengine
  type(c_ptr), value :: my_app
  fortran_app = my_app
end subroutine set_android_app

subroutine menu_toggle()
  use dustengine
  if(menu_on)then
    menu_on = .false.
  else
    menu_on = .true.
  endif
end subroutine menu_toggle

!subroutine update_multitouch(newtouch_x,newtouch_y)
!  use dustengine
!  integer(c_int), intent(in) :: newtouch_x,newtouch_y
!  integer i
!  do i = 1,8
!    if(m

! get touch events from the device
subroutine dust_com_touch(my_touch_x, my_touch_y, my_touch_pressure, my_pId,my_Action) bind(c)
  use dustengine
  integer(c_int), intent(in) :: my_pId,my_touch_x,my_touch_y,my_Action
  real(c_float), intent(in) :: my_touch_pressure
  integer i, pId
  mtouch_pressure = my_touch_pressure
  pId = my_pId + 1
  mtouch_x(pId) = my_touch_x
  mtouch_y(pId) = my_touch_y
  mtouch_action(pId) = my_Action

!  if(my_action(1) == 1 .and. menu_on .and. touch_override)then
!      call menu_toggle()
!      return
!  elseif(touch_override)then
!      return
!  endif

  touch_pressure = mtouch_pressure(1)
  touch_action = mtouch_action(1)

  ! check to see if any pointers are down
  touch_down = .false.
  do i = 1,8
    if(mtouch_action(i) == 0 .or. mtouch_action(i) == 2)then
      touch_down = .true.
    endif
  enddo

  if(my_Action == 0 .or. my_Action == 5 .or. my_Action == 2)then
    mtouch_down(pId) = .true.
    if(pId == 1)then
      mouse_x0 = mouse_x
      mouse_y0 = mouse_y
      mouse_x = mtouch_x(1)
      mouse_y = mtouch_y(1)
    endif
  elseif(my_Action == 1 .or. my_Action == 6)then
    mtouch_down(pId) = .false.
  endif

  if(touch_action == 1 .and. menu_on)then
      call update_menu()
  endif

!  write(10,'(4(a,i4))')'touch pId = ',pId,' x = ',my_touch_x,' y = ',my_touch_y,&
!                          ' action = ',my_Action
!  write(10,*)mtouch_action
!  write(10,*)"my_pId=",pId," my_Action=",my_Action
!  flush(10)
  if(touchdelay > 0.0)then
    touchdelay = touchdelay - dt
    !gravity_on = .true.
    textloop = .true.
  else
    touch_on = .true.
    touchdelay = 0.0
    drawtext = .false.
    textontimer = 0.0
  endif
end subroutine dust_com_touch

! act on touch events
subroutine touch_events()
  use dustengine
  integer i,j,pn1,pn2,ngroup,mypx,mypy,mypid,thispid(8)
  !write(10,*)"touch_down = ",touch_down," touch_on = ",touch_on
  !flush(10)
  if(touch_on.and..not.menu_on)then
    !write(10,*)"calling touch action.."
    !flush(10)
    ! get the current down pointers
    mtouch_npointers = 0
    thispid = 0
    do i = 1,8
      if(mtouch_down(i))then
        mtouch_npointers = mtouch_npointers+1
        thispid(mtouch_npointers) = i
      endif
    enddo
    if(attract_on .or. repel_on)then
      do i = 1,mtouch_npointers
         ngroup = ndropped/mtouch_npointers
         pn1 = 1 + i*ngroup - ngroup
         pn2 = i*ngroup
         mypx = mtouch_x(thispid(i))
         mypy = mtouch_y(thispid(i))
         !write(10,*)mypx,mypy,pn1,pn2,ngroup
         !flush(10)
         if(attract_on)call attract(mypx,mypy,2.0,pn1,pn2)
         if(repel_on)call repel(mypx,mypy,150.0)
      enddo
    endif
    if(swirl_on)call swirl(1.0,ndropped)
    if(start_message .and. nparticles_selected)then
      textdropped = 0
      start_message = .false.
    endif
  endif
end subroutine touch_events

subroutine select_nparticles()
  use shared_data
  use dustengine
  implicit none
  INTEGER*4 :: count,i,npts
  real pdx,pdy,pvang,pvmag,pvx,pvy
  character*500 messagetext,oldmessage
  messagetext = "Number of Particles\&400    800   1200"
  call setup_text(messagetext,-999,-999)
  ! update the point array
  ndropped = textdropped
  if(touch_action == 1 .and. .not. nparticles_selected)then
    nparticles_selected = .true.
    if(mouse_x > float(width)/3.0 .and. mouse_x < float(width)*(2.0/3.0))then
      nparticles = nparticles * 2
    elseif(mouse_x > float(width)*(2.0/3.0))then
      nparticles = nparticles * 3
    endif
    call repel(mouse_x,mouse_y,300.0)
    collision_on = .true.
    gravity_on = .true.
    write(messages(5),'(i4,1x,a)')nparticles,"Particles"
  endif
  if(gravity_on)call applygravity()
  if(collision_on)call collidepoints()
  if(nparticles_selected)then
    nparticles_selected_timer = nparticles_selected_timer - dt
    if(nparticles_selected_timer <= 0.0)then
      nparticles_select = .false.
      ndropped = 0
      textdropped = 0
      collision_on = .false.
      gravity_on = .false.
      ttotal = 0.0
      do i = 1,nparticles
        particle(x,i) = -width/2.0
        particle(y,i) = -height/2.0
        particle(vmag,i) = 0.0
        particle(vang,i) = 0.0
        particle(ptem,i) = 1.0
        particle(vx,i) = 0.0
        particle(vy,i) = 0.0
        pointxy(x,i) = 0.0
        pointxy(y,i) = 0.0
      enddo
    endif
  else
    call pull_text(5.0)
  endif
  do i = 1, ndropped
    !pvmag = particle(vmag,i)
    !pvang = particle(vang,i)
    pvx = particle(vx,i) !pvmag*cos(pvang)
    pvy = particle(vy,i) !pvmag*sin(pvang)
    pdx = pvx*dt
    pdy = pvy*dt
    particle(x,i) = particle(x,i)+pdx
    particle(y,i) = particle(y,i)+pdy
!     if(particle(ptem,i) > 0.0)then
!       particle(ptem,i) = particle(ptem,i)-dt*particle(ptem,i)*.5
!      else
!        particle(ptem,i) = 0.0
!      endif
  enddo
    call colortemp(0.0,1.0)
    !pointcolor = 0.8
    ! update the array of things to actually draw
    ! ... for now it is everything
  do i = 1, ndropped
    pointxy(:,i) = (/particle(x,i),particle(y,i)/)
  enddo
end subroutine select_nparticles
  
! Main subroutine to control point interactions
subroutine rundemo()
    use shared_data
    use dustengine
    implicit none
    INTEGER*4 :: count,i,npts
    real pdx,pdy,pvang,pvmag,pvx,pvy
    character*500 messagetext,oldmessage
    if(framecount > 5.0)then
      call fpsupdate()
    endif
    !if(ndropped == nparticles - 1)then
      !ndropped = ndropped + 1
      !call spiraldrop(spiralfactor)
    !endif
    if(droptimer >= droptime .and. ndropped < nparticles)then
      do i = 1,3
        ndropped = ndropped + 1
        !call raindrop()
        if(ndropped <= nparticles) call spiraldrop(spiralfactor)
        if(ndropped > nparticles)ndropped = nparticles
      enddo
      droptimer = 0.0
    endif
    if(ndropped > nparticles - 5 .and. ndropped < nparticles)then
      gravity_on = .true.
      collision_on = .true.
      attract_on = .true.
      menu_button(1) = 1
      menu_button(2) = 1
      menu_button(3) = 1
    endif
    if(firstpass == 1)then
      ndropped = 1
      firstpass = 0
      call system_clock(time1, count_rate, count_max)
      time0 = time1
      ttotal = 0
      mouse_x = float(width)/2.0
      mouse_y = float(height)/2.0
     call init_font()
     call system_clock(start_time,count_rate,count_max)
     accelz0 = accelz
     psize = psize * float(width)/960.0  ! scale to bionic 960 pixel width
     bminx = psize/2.0
     bmaxx = xmax-psize/2.0
     bminy = psize/2.0
     bmaxy = ymax-psize/2.0
     touch_on = .false.
     !messagetext = trim(adjustl(messages(message)))
     !call setup_text(messagetext,-999,-999)
     write(10,*)"particle size = ",psize," bmaxx = ",bmaxx," bmaxy = ",bmaxy
     flush(10)
    endif
    ! show the particle selection dialog
    if(nparticles_select)then
      call select_nparticles()
      return
    endif
!    if(ndropped <= nparticles .and. .not. alldropped)then
      !call spiraldrop(spiralfactor)
!      call raindrop()
!      if(ndropped == nparticles)then
!        alldropped = .true.
!      endif
!    endif
!    if(ndropped == nparticles*3)then
    if(credits_on .and. .not. credits_running)then
      credits_running = .true.
      textloop = .true.
      menu_button(2) = 1
      collision_on = .true.
      text_delay = 5.0
      textontimer = text_delay
      !call repel(2.0)
    endif
    if(gravity_on)call applygravity()
    if(collision_on)call collidepoints()
    call collidewalls()
    ! update the point array
    do i = 1, ndropped
      !pvmag = particle(vmag,i)
      !pvang = particle(vang,i)
      !pvx = pvmag*cos(pvang)
      !pvy = pvmag*sin(pvang)
      pvx = particle(vx,i)
      pvy = particle(vy,i)
      pdx = pvx*dt
      pdy = pvy*dt
      particle(x,i) = particle(x,i)+pdx
      particle(y,i) = particle(y,i)+pdy
      if(particle(ptem,i) > 0.0)then
        particle(ptem,i) = particle(ptem,i)-dt*particle(ptem,i)*.5
      else
        particle(ptem,i) = 0.0
      endif
    enddo
    call colortemp(0.0,1.0)
    !pointcolor = 0.8
    ! update the array of things to actually draw
    ! ... for now it is everything
    do i = 1, ndropped
      pointxy(:,i) = (/particle(x,i),particle(y,i)/)
    enddo
    !call draw_ui()
    droptimer = droptimer + dt
    if(drawtext .and. textloop)then
      textdroptimer = textdroptimer + dt
      if(textdroptimer >= textdroptime)then
        if(textdropped < ui_ptn)then
          textdropped = textdropped + 3
        endif
        textdroptimer = 0.0
      endif
    endif
    ! display the help message at first
    if(ndropped == nparticles .and. start_message .and. ttotal > 7.0)then
      messagetext = ""
      write(messagetext,'(a)')"Press MENU\Button\For Options"
      call setup_text(messagetext,-999,-999)
      call pull_text(3.0)
    endif
    ! update the text looper
    if(textloop .and. credits_running)then
      textontimer = textontimer + dt
      if(textontimer >= text_delay)then
        text_delay = 5.0
        drawtext = .true.
        textontimer = 0.0
        write(10,*)"message = ",message," nmessages = ",nmessages
        flush(10)
        if(message > nmessages)then
          drawtext = .false.
          gravity_on = .true.
          menu_button(1) = 1
          credits_running = .false.
          textloop = .false.
          credits_on = .false.
          menu_button(7) = 0
          message = 0
        endif
        if(messages(message) == "FPS")then
          messagetext = ""
          write(messagetext,'(f6.1,a)')fps," FPS"
          messagetext = trim(adjustl(messagetext))
        elseif(message <= nmessages)then
          messagetext = trim(adjustl(messages(message)))
        endif
        call setup_text(messagetext,-999,-999)
        textdropped = 0
        message = message + 1
      endif
      mouse_x = width/2
      mouse_y = 0
      call repel(mouse_x,mouse_y,50.0)
      do i = 1,textdropped
        pointcolor(:,i) = 1.0
      enddo
    endif
    if(benchmark_on)then
      if(benchmark_start)then
        messagetext = "Starting Benchmark"
        oldmessage = ""
        call setup_text(messagetext,-999,height/12)
        drawtext = .false.
        credits_on = .false.
        textloop = .false.
        textdropped = ui_ptn
        touch_override = .true.
        touch_on = .true.
        if(ndropped == nparticles)benchmark_start = .false.
        benchmark_time = 0.0
        call pull_text(10.0)
        benchmark_frames = 0
        benchmark_x = float(width)/2.0
        benchmark_y = float(height)/2.0
        benchmark_done = .false.
        write(10,*)"...benchmark staring.. ndropped = ",ndropped," nparticles = ",nparticles
        flush(10)
      else
        if(benchmark_time >= 2.0 .and..not. benchmark_done)then
          oldmessage = trim(adjustl(messagetext))
          write(messagetext,'(a,1x,i2)')"Benchmark Time",int(21-benchmark_time)
          if(trim(adjustl(messagetext)) /= trim(adjustl(oldmessage)))then
            call setup_text(messagetext,width/12,height/12)
            textdropped = ui_ptn
          endif
        endif
        benchmark_time = benchmark_time + dt
        if(benchmark_time >= 0.1)then
          benchmark_frames = benchmark_frames + 1
          mouse_x = benchmark_x
          mouse_y = benchmark_y
          touch_down = .true.
          call pull_text(10.0)
          if(benchmark_time > 2.0 .and. benchmark_time <= 4.0)then
            mouse_x = 1*width/10
            mouse_y = 9*height/10
          elseif(benchmark_time > 4.0 .and. benchmark_time <= 6.0)then
            mouse_x = 9*width/10
            mouse_y = 1*height/10
          elseif(benchmark_time > 6.0 .and. benchmark_time <= 8.0)then
            mouse_x = 9*width/10
            mouse_y = 9*height/10
          elseif(benchmark_time > 8.0 .and. benchmark_time <= 10.0)then
            mouse_x = 1*width/10
            mouse_y = 9*height/10
          elseif(benchmark_time > 10.0 .and. benchmark_time <= 12.0)then
            mouse_x = 9*width/10
            mouse_y = 9*height/10
          elseif(benchmark_time > 12.0 .and. benchmark_time <= 14.0)then
            mouse_x = 1*width/10
            mouse_y = 9*height/10
          elseif(benchmark_time > 14.0 .and. benchmark_time <= 20.0)then
            mouse_x = width/2
            mouse_y = height/2
          elseif(benchmark_time > 20.0 .and..not. benchmark_done)then
            benchmark_fps = float(benchmark_frames)/(benchmark_time-.1)
            !write(10,*)"Benchmark Complete.."
            !flush(10)
            messagetext = ""
            write(messagetext,'(a,f6.1,a)')"Benchmark Complete\ ",benchmark_fps," FPS"
            call setup_text(messagetext,-999,-999)
            benchmark_done = .true.
            touch_down = .false.
            gravity_on = .true.
            menu_button(1) = 1
            swirl_on = .false.
            menu_button(5) = 0
            touch_override = .false.
            collision_on = .false.
            menu_button(2) = 0
            !textdropped = 0
          elseif(benchmark_time >= 27.0 .and. benchmark_time < 30.0)then
            collision_on = .true.
            menu_button(2) = 1
            textdropped = 0
          elseif(benchmark_time > 30.0)then
            benchmark_on = .false.
            menu_button(6) = 0
          endif
        endif
      endif
    endif
end subroutine rundemo


