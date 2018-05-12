module input_devices
    use globals
    use iso_c_binding
    implicit none

  ! accelerometer data
    real :: accelx = 0.0
    real :: accely = 0.0
    real :: accelz = 0.0
    ! flag to signal an update
    logical :: accel_update = .false.
  ! key press data
    integer :: key_num = 0
    integer :: key_action = 0
    ! flag to signal an update
    logical :: key_update = .false.
  ! multi-touch data for up to 10 pointers
    integer :: touch_xy(2,10) = 0
    integer :: touch_last_xy(2,10) = 0
    integer :: touch_action(10) = 0
    integer :: touch_last_action(10) = 0
    real :: touch_pressure(10) = 0.0
    integer :: npointers = 0
    real :: touch_diameter = 0.0

  contains

    subroutine process_touch()
        integer i,j
        integer active_pointers(10)
        real p1x1,p1x2,p1y1,p1y2,p2x1,p2x2,p2y1,p2y2,&
             dist1,dist2,zoom_factor,trans_factor,tmp_zoom
        ! get the number of active pointers
        npointers = 0
        active_pointers = 0
        do i = 1,10
            if(touch_action(i) == 2)then
               npointers = npointers + 1
               active_pointers(npointers) = i
            endif
        enddo
        ! translate.. only one active pointer.. calculate the distance
        ! from the last known position
        if(npointers == 1)then
          p1x1 = touch_last_xy(x,active_pointers(1))
          p1x2 = touch_xy(x,active_pointers(1))
          p1y1 = touch_last_xy(y,active_pointers(1))
          p1y2 = touch_xy(y,active_pointers(1))
          ! adjust the camera
          trans_factor = 1.0-(camera1%zoom - &
               camera1%zoom1)/(camera1%zoom_max-camera1%zoom_min)
          camera1%dx = camera1%dx + (p1x2-p1x1)
          camera1%dy = camera1%dy + (p1y1-p1y2)
          paused = .false.
        endif
        ! zoom.. calculate the distance from the first active pointer
        ! to the second active pointer for now and
        if(npointers > 1)then
          p1x1 = touch_last_xy(x,active_pointers(1))
          p1x2 = touch_xy(x,active_pointers(1))
          p1y1 = touch_last_xy(y,active_pointers(1))
          p1y2 = touch_xy(y,active_pointers(1))
          p2x1 = touch_last_xy(x,active_pointers(2))
          p2x2 = touch_xy(x,active_pointers(2))
          p2y1 = touch_last_xy(y,active_pointers(2))
          p2y2 = touch_xy(y,active_pointers(2))
          dist1 = sqrt((p2x1-p1x1)**2+(p2y1-p1y1)**2)
          dist2 = sqrt((p2x2-p1x2)**2+(p2y2-p1y2)**2)
          zoom_factor = 1.0 + (dist2-dist1)/dist1
          tmp_zoom = camera1%zoom*zoom_factor
          if(tmp_zoom >= camera1%zoom_min .and.&
             tmp_zoom <= camera1%zoom_max)then
             camera1%zoom = tmp_zoom
             camera1%pzoom = camera1%pzoom*zoom_factor
          endif
          !write(logstr,*)"zoom = ",camera1%zoom
          !call flogi(logstr)
        endif
        ! set limits on the camera zoom
        if(camera1%zoom > camera1%zoom_max)then
          camera1%zoom = camera1%zoom_max
        elseif(camera1%zoom < camera1%zoom_min)then
          camera1%zoom = camera1%zoom_min
        endif
    end subroutine process_touch

end module input_devices
