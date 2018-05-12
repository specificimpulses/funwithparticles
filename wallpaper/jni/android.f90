module android
    use iso_c_binding
    use input_devices
    use globals
    use timers
    use collisions
    use effects
    implicit none
    type(c_ptr) android_app
    !type(c_ptr) android_asset
    !type(c_ptr) asset_buffer

    interface
        subroutine fortran_process_events(my_app) bind(c,name="fortran_process_events")
            use iso_c_binding
            type(c_ptr), value :: my_app
        end subroutine fortran_process_events
    end interface

    interface
        subroutine clogi(my_string) bind(c,name="clogi")
            use iso_c_binding
            character(kind=c_char) :: my_string(*)
        end subroutine clogi
    end interface

    interface
        type(c_ptr) function get_asset(my_app,my_asset_name)&
         bind(c,name="get_asset")
            use iso_c_binding
            type(c_ptr), value :: my_app
            character(kind=c_char) :: my_asset_name(*)
        end function get_asset
    end interface

    interface
        type(c_ptr) function get_asset_buffer(my_asset)&
         bind(c,name="get_asset_buffer")
            use iso_c_binding
            type(c_ptr), value :: my_asset
        end function get_asset_buffer
    end interface

    interface
        integer function get_asset_size(my_asset)&
         bind(c,name="get_asset_size")
            use iso_c_binding
            type(c_ptr), value :: my_asset
        end function get_asset_size
    end interface

  contains

    real(c_float) function fortran_color() bind(c)
        use iso_c_binding
        fortran_color = 0.5
    end function fortran_color

    subroutine enable_gravity(my_gravity_enabled) bind(c)
        logical(c_bool), intent(in), value :: my_gravity_enabled
        gravity_enabled = my_gravity_enabled
    end subroutine enable_gravity

    subroutine set_gravity(my_gravity) bind(c)
        real(c_float), intent(in), value :: my_gravity
        gravity = my_gravity
    end subroutine set_gravity

    subroutine set_attract(my_attract) bind(c)
        real(c_float), intent(in), value :: my_attract
        attract = my_attract
    end subroutine set_attract

    subroutine enable_touch(my_touch_enabled) bind(c)
        logical(c_bool), intent(in), value :: my_touch_enabled
        touch_enabled = my_touch_enabled
    end subroutine enable_touch

    subroutine update_nparticles(my_nparticles, my_particlesize) bind(c)
        integer(c_int), intent(in), value :: my_nparticles
        integer(c_int), intent(in), value :: my_particlesize

        write(logstr,*)"update_nparticles .. my_nparticles = ",my_nparticles
        call flogi(logstr)
        if(my_nparticles /= nparticles)then
          resetparticles = .true.
        endif
          nparticles = my_nparticles
          psize = real(my_particlesize)
          call setup_particle_engine(screen1%width,screen1%height)
    end subroutine update_nparticles

    subroutine setup_particle_engine(my_width, my_height) bind(c)
        integer(c_int), intent(in), value :: my_width, my_height
        character*200 logstring
        !nparticles = my_nparticles
        !psize = 8.0
        screen1%width = my_width
        screen1%height = my_height
        screen1%aspect = float(my_width)/float(my_height)
        write(logstring,'(a,i6,a,i6,a,i6)')"...screen1 width = ",screen1%width," height = ",screen1%height,&
        ".. nparticles = ",nparticles
        call flogi(logstring)
        if(t_total < 2.0)resetparticles = .true.
        if(resetparticles)then
          write(logstring,'(a,a)')"... resetparticles called "
          call flogi(logstring)
          call init_particle_arrays()
          call init_timers()
          call init_particle_xy()
          call set_point_xy()
          pvmax = float(max(screen1%width,screen1%height))*4.0
          resetparticles = .false.
        endif
    end subroutine setup_particle_engine

    subroutine init_particle_arrays()
        integer i,j
        if(allocated(particle))deallocate(particle)
        if(allocated(pointcolor0))deallocate(pointcolor0)
        if(allocated(pointxy))deallocate(pointxy)
        if(allocated(pointcolor))deallocate(pointcolor)
        allocate(particle(9,nparticles*3))
        allocate(pointxy(2,nparticles*3))
        allocate(pointcolor0(4,nparticles*3))
        allocate(pointcolor(4,nparticles*3))
        c_pointxy = c_loc(pointxy)
        c_pointcolor = c_loc(pointcolor)
        ndropped = nparticles
        do i = 1,nparticles
          do j = 1,nprops
            particle(j,i) = 0.0
          enddo
          pointxy(x,i) = 0.0
          pointxy(y,i) = 0.0
          pointcolor0(r,i) = 0.3
          pointcolor0(g,i) = 0.3
          pointcolor0(b,i) = 0.3
          pointcolor0(a,i) = 1.0
          pointcolor(r,i) = 0.3
          pointcolor(g,i) = 0.3
          pointcolor(b,i) = 0.3
          pointcolor(a,i) = 1.0
        enddo
    end subroutine init_particle_arrays

    subroutine set_point_xy()
        integer i
        real dw,dh
        dw = 2.0/float(screen1%width)
        dh = 2.0/float(screen1%height)
        do i = 1,nparticles
           pointxy(x,i) = -1.0+particle(x,i)*dw
           pointxy(y,i) = -1.0+particle(y,i)*dh
        enddo
    end subroutine set_point_xy

    subroutine update_particle_engine() bind(c)
        character*200 fps_string
        call update_timers()
        call collide_walls()
        call collide_points()
        if(gravity_enabled) call applygravity()
        if(t_total < 0.0)then
            call repel(screen1%width/2,screen1%height/2,5.0)
        endif
        if(touch_action(1) == 2 .and. touch_enabled)then
            call attract_particles(touch_xy(x,1),touch_xy(y,1),attract,1,ndropped)
        endif
        call colortemp(0.0,1.0)
        call update_particle_positions()
        if(fps_print)then
          write(fps_string,'(a,f8.2,a)')"Particle Engine : ",fps," FPS"
          fps_string = trim(adjustl(fps_string))
          call flogi(fps_string)
        endif
    end subroutine update_particle_engine

    subroutine update_particle_positions()
        integer i
        real pdx,pdy,pvang,pvmag,pvx,pvy
        do i = 1,ndropped
          pvmag = particle(vmag,i)
          pvang = particle(vang,i)
          pvx = pvmag*cos(pvang)
          pvy = pvmag*sin(pvang)
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
        call set_point_xy()
    end subroutine update_particle_positions

    subroutine update_accel(msensorx,msensory,mrotation) bind(c)
        real(c_float), intent(in), value :: msensorx, msensory
        integer(c_int), intent(in), value :: mrotation
        !write(logstr,*)"msensorx = ",msensorx," msensory = ",msensory
        !call flogi(logstr)
        !return
        accelx = msensorx
        accely = msensory
        screen1%rotation = mrotation
    end subroutine update_accel

    subroutine init_particle_xy()
        integer i
        do i = 1,nparticles
            particle(x,i) = screen1%width/2.0+(-0.5+rand())*(float(screen1%width)/5.0)
            particle(y,i) = screen1%height/2.0+(-0.5+rand())*(float(screen1%height)/5.0)
            particle(ptem,i) = 1.0
        enddo
    end subroutine init_particle_xy

    ! store a pointer to the android app struct
    subroutine set_android_app(my_app) bind(c)
        type(c_ptr), value :: my_app
        character*200 logstring
        android_app = my_app
        write(logstring,*)"android_app = ",android_app
        call flogi(logstring)
    end subroutine set_android_app

    ! write a message to the android log
    subroutine flogi(my_string)
        !character :: my_string(*)
        character, intent(in) :: my_string*200
        character*201 dumchar
        write(dumchar,'(a)')trim(adjustl(my_string))//c_null_char
        call clogi(trim(dumchar))
    end subroutine flogi

    ! get sensor data and modify the engine state
    subroutine dust_com_sensors(my_accelx,my_accely,my_accelz) bind(c)
      real(c_float), intent(in) :: my_accelx, my_accely, my_accelz
      character(c_char) :: logstring*200
      accelx = my_accelx
      accely = my_accely
      accelz = my_accelz
      write(logstring,*)"accelx=",accelx,"  accely=",accely,&
      "  accelz=",accelz,c_null_char
      !call clogi(trim(adjustl(logstring)))
    end subroutine

    ! get key presses
    subroutine dust_com_key(my_Code,my_Action) bind(c)
      integer, intent(in) :: my_Code,my_Action
      character(c_char) :: logstring*200
      key_num = my_Code
      key_action = my_Action
      write(logstring,*)"key_num=",key_num," key_action=",&
      key_action,c_null_char
      !call clogi(trim(adjustl(logstring)))
    end subroutine dust_com_key

    ! get touch event from device (single touch)
    subroutine update_touch(my_touch_x,my_touch_y,my_action) bind(c)
        real(c_float), intent(in), value :: my_touch_x, my_touch_y
        integer(c_int), intent(in), value :: my_action
        touch_xy(x,1) = my_touch_x
        touch_xy(y,1) = my_touch_y
        touch_action(1) = my_action
    end subroutine update_touch

    ! get touch events from the device(multi-touch)
    subroutine dust_com_touch(my_touch_x, my_touch_y, my_touch_pressure, my_pointr,my_Action) bind(c)
      integer(c_int), intent(in) :: my_pointr,my_touch_x,my_touch_y,my_Action
      real(c_float), intent(in) :: my_touch_pressure
      integer i, pointr
      character(c_char) :: logstring*200
      pointr = my_pointr + 1
      touch_pressure(pointr) = my_touch_pressure
      touch_last_xy(x,pointr) = touch_xy(x,pointr)
      touch_last_xy(y,pointr) = touch_xy(y,pointr)
      touch_xy(x,pointr) = my_touch_x
      touch_xy(y,pointr) = my_touch_y
      touch_last_action(pointr) = touch_action(pointr)
      touch_action(pointr) = my_Action
      npointers = pointr
      ! build the log message
      !logstring = ""
      !write(logstring,*)"pointr ",pointr,": x=",touch_xy(x,pointr)," y=",touch_xy(y,pointr)," pressure=",&
      !                    touch_pressure(pointr)
      !call flogi(logstring)
    end subroutine dust_com_touch
end module android
