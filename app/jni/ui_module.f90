module ui_module
use shared_data

contains

  !Initialize a dot matrix font to use with iachar("X") function
  subroutine init_font()
    allocate(dmfont(128,35)) !(iachar,row,col)
    dmfont = 0
    ! setup numbers
    include 'dmfont.f90'
    write(10,*)"initializing font engine"
    flush(10)
  end subroutine init_font

  ! for now the UI just shows the fps, current time and best time
  subroutine setup_text(mytext,textx0,texty0)
    integer i,j,ui_line,ui_char,dm_on,dm_pt,dm_row,dm_col,&
            textx0,texty0,nchars,nlines,mychar,maxchars
    character mytext*500,ui_lines(20)*50,thischar*1
    real dx,dy,shiftx,shifty,my_x,my_y,xwidth,ywidth,yoff
    ! parse the text string and build the ui_lines array
    dm_size = psize
    nchars = len(trim(adjustl(mytext)))
    !write(10,'(a)')trim(adjustl(mytext))
    !flush(10)
    nlines = 1
    mychar = 0
    ui_lines = ""
    maxchars = 0
    do i = 1,nchars
      thischar = mytext(i:i)
      if(thischar == "\")then
        nlines = nlines + 1
        mychar = 0
      else
        mychar = mychar+1
        ui_lines(nlines)(mychar:mychar) = thischar
        if(mychar > maxchars)maxchars = mychar
      endif
    enddo
    ! set initial location for text
    if(textx0 == -999.)then
      xwidth = maxchars*psize*6.0
      dx = float(width)/2.0 - xwidth/2.0
    else
      dx = textx0
    endif
    if(texty0 == -999.)then
      ywidth = nlines*psize*8.0
      dy = float(height)/2.0 - ywidth/2.0
    else
      dy = texty0
    endif
!    write(10,*)"maxchars = ",maxchars," xwidth = ",xwidth," dx = ",dx
!    flush(10)
    ! load the vertex array for the ui text
    ui_ptn = 0
    ui_text = 0.0
    do ui_line = 1,nlines
      do ui_char = 1,len_trim(ui_lines(ui_line))
        thischar = ui_lines(ui_line)(ui_char:ui_char)
        if(thischar == "p" .or. thischar == 'g' .or. &
           thischar == "y" .or. thischar == ',')then
           yoff = psize*2
        else
           yoff = 0
        endif
        dm_pt = 0
        do dm_row = 1,7
          do dm_col = 1,5
            dm_pt = dm_pt + 1
            dm_on = dmfont(iachar(thischar),dm_pt)
            if(dm_on == 1)then
              ui_ptn = ui_ptn + 1
              my_x = float(dm_col)*dm_size
              my_y = float(dm_row)*dm_size+yoff
              ui_text(x,ui_ptn) = my_x+dx
              ui_text(y,ui_ptn) = my_y+dy
            endif
          enddo
        enddo
        dx = dx + dm_size*6.0
      enddo
      dy = dy + dm_size*10.0
      dx = dx - dm_size*6.0*len_trim(ui_lines(ui_line))
    enddo
    textdropped = ui_ptn !- 1
  end subroutine setup_text

subroutine update_menu()
  real bminx,bw,bminy,bh
  integer i
  integer btoggle(7),untoggle(7)
  write(10,*)"update_menu called, mouse_x = ",mouse_x," mouse_y = ",mouse_y
  flush(10)
  bminx = float(width)*.75
  bminy = 0.0
  bw = width/4.5
  bh = height/7.0
  btoggle = 0
  untoggle = 0
  ! set the toggles based on the mouse pointer location
  ! include a small delay to suppress pointer bounce
  if(mouse_x >= bminx .and. button_delay <= 0.0)then
    do i = 1,7
      if(mouse_y >= bh*(float(i-1)) .and. &
         mouse_y <= bh*(float(i)))then
         btoggle(i) = 1
         write(10,*)"btoggle(",i,") activated"
         flush(10)
      else
         btoggle(i) = 0
      endif
    enddo
    button_delay = 0.2
  else
    return
  endif
  ! apply the toggles to the menu button shader uniform
  do i = 1,7
    if(btoggle(i) == 1)then
      write(10,*)"btoggle(",i,") set"
      flush(10)
      if(menu_button(i) /= 0)then
        menu_button(i) = 0
      else
        menu_button(i) = 1
      endif
    endif
  enddo
  ! apply the toggles to the corresponding global switches
  ! gravity
  if(btoggle(1) == 1)then
    if(gravity_on)then
       gravity_on = .false.
    else
       gravity_on = .true.
    endif
  endif
  ! collision detection
  if(btoggle(2) == 1)then
    if(collision_on)then
       collision_on = .false.
    else
       collision_on = .true.
    endif
  endif
  ! attract to pointer
  if(btoggle(3) == 1)then
    if(attract_on)then
       attract_on = .false.
    else
       attract_on = .true.
       ! untoggle repel and swirl
       !repel_on = .false.
       swirl_on = .false.
       !menu_button(4) = 0
       menu_button(5) = 0
    endif
  endif
  ! repel from pointer
  if(btoggle(4) == 1)then
    if(repel_on)then
       repel_on = .false.
    else
       repel_on = .true.
       ! untoggle attract and swirl
       !attract_on = .false.
       swirl_on = .false.
       !menu_button(3) = 0
       menu_button(5) = 0
    endif
  endif
  ! swirl attract
  if(btoggle(5) == 1)then
    if(swirl_on)then
       swirl_on = .false.
    else
       swirl_on = .true.
       ! untoggle attract and repel
       attract_on = .false.
       repel_on = .false.
       menu_button(3) = 0
       menu_button(4) = 0
    endif
  endif
  ! Benchmark
  if(btoggle(6) == 1)then
    if(benchmark_on)then
       benchmark_on = .false.
    else
       swirl_on = .true.
       collision_on = .true.
       ! untoggle everything except benchmark and collisions
       attract_on = .false.
       repel_on = .false.
       gravity_on = .false.
       benchmark_on = .true.
       benchmark_start = .true.
       benchmark_time = 0.0
       menu_button(1) = 0
       menu_button(2) = 1
       menu_button(3) = 0
       menu_button(4) = 0
       menu_button(5) = 1
       menu_button(6) = 1
    endif
  endif
  ! Credits
  if(btoggle(7) == 1)then
    if(credits_on)then
       credits_on = .false.
    else
       credits_on = .true.
    endif
  endif
!  write(10,*)"ui_delay set to 0.5"
!  flush(10)
  ui_delay = 0.5
end subroutine update_menu

end module ui_module

