module effects
  use globals
  use timers
  use input_devices

  contains

  !This routine creates a randomized raindrop pattern from the ceiling
  subroutine raindrop()
    real xdrop,ydrop,pvmag,pvang
    ! generate a random x location to drop from
    xdrop = 0.0*xmax+rand()*xmax*1.0 
    ! drop from slightly above the screen
    ydrop = -100
    pvmag = 10+rand()*20
    !put a small perturbation on the release direction
    pvang = (90+(rand()*10-5))/d2r  
    particle(x,ndropped) = xdrop
    particle(y,ndropped) = ydrop
    particle(vmag,ndropped) = pvmag
    particle(vang,ndropped) = pvang
  end subroutine raindrop

  ! set particles in a sprialing pattern
  ! myspeed sets the 'tighness' of the spiral
  subroutine spiraldrop(myspeed)
    real xdrop,ydrop,x0,y0,radius,radmax,radangle,myspeed
    ! set x0,y0 to center of device screen
    x0 = float(screen1%width)/2.0
    y0 = float(screen1%height)/2.0
    radmax = min(x0,y0)*.5
    radius = radmax - radmax*(float(nparticles-ndropped)/float(nparticles))
    radangle = myspeed*(((float(nparticles)*1.2-float(ndropped))**2.0/d2r))
    particle(x,ndropped) = x0+radius*cos(radangle)
    particle(y,ndropped) = y0+radius*sin(radangle)
  end subroutine spiraldrop

  subroutine attract_particles(my_x,my_y,power,pn1,pn2)
    real px0,py0,pvx0,pvy0,pixx,pixy,distx,disty,distxy,&
         dx0,dy0,pvmag,pvang,pull,dfactx,dfacty,pvx1,pvy1,&
         pvx2,pvy2,mindist,power,powxy
    integer i,my_x,my_y,pn1,pn2
    ! pull all of the particles toward the touch location as a
    ! function of the touch pressure and the gravity scaling factor
    !my_y = my_y + real(screen1%height)/2.0
    do i = min(pn1,ndropped),min(pn2,ndropped)
        ! get the particle position
        px0 = particle(x,i)
        py0 = particle(y,i)
        pvmag = particle(vmag,i)
        pvang = particle(vang,i)
        ! calculate velocity vector from direction and magnitude
        pvx0 = pvmag*cos(pvang)
        pvy0 = pvmag*sin(pvang)
        ! store the mouse location in floats
        pixx = float(my_x)
        pixy = float(screen1%height-my_y)
        ! calculate the distance from the particle to the touch location
        distx = pixx - px0
        disty = pixy - py0
        dx0 = 0.0
        dy0 = 0.0
        distxy = sqrt(distx**2+disty**2)
        powxy = min(float(screen1%width)/2.0,max(1.0,power*distxy))
        pvx1 = powxy*(distx/distxy)
        pvy1 = powxy*(disty/distxy)
        pvx2 = pvx0+pvx1
        pvy2 = pvy0+pvy1
        ! calculate the new particle speed and direction
        pvmag = sqrt(pvx2**2+pvy2**2)
        ! limit the speed to the max allowed
        if(pvx2 > pvmax)pvx2 = pvmax
        if(pvx2 < -pvmax)pvx2 = -pvmax
        if(pvy2 > pvmax)pvy2 = pvmax
        if(pvy2 < -pvmax)pvy2 = -pvmax
        pvang = atan2(pvy2,pvx2)
       ! update the particle properties
       !particle(x,i) = px0+dx0
       !particle(y,i) = py0+dy0
        particle(vmag,i) = pvmag
        particle(vang,i) = pvang
       !endif
       !particle(vx,i) = pvx2
       !particle(vy,i) = pvy2
    enddo
  end subroutine attract_particles

  ! explode!
  subroutine repel(my_x,my_y,power)
    real px0,py0,pvmag,pvang,mcentx,mcenty,pvx0,pvy0,&
         blastang,blastmag,power,pvx1,pvy1
    integer pnum,i,my_x,my_y
      mcentx = my_x 
      mcenty = my_y
  ! launch each point radially out from the centroid
    do i = 1,ndropped
      pnum = i
      px0 = particle(x,pnum)
      py0 = particle(y,pnum)
      pvmag = particle(vmag,pnum)
      pvang = particle(vang,pnum)
      pvx0 = pvmag*cos(pvang)
      pvy0 = pvmag*sin(pvang)
      ! calcuate the vector from the centroid to the current point     
      blastang = atan2((mcenty-py0),(mcentx-px0))
      ! scale the magnitude by the distance from the center
      blastmag = (10.0*(power/(sqrt((mcentx-px0)**2+(mcenty-py0)**2))))**2
      pvx1 = -blastmag*cos(blastang) + pvx0
      pvy1 = -blastmag*sin(blastang) + pvy0
      pvang = atan2(pvy1,pvx1)
      pvmag = sqrt(pvx1**2+pvy1**2)
      particle(vmag,pnum) = pvmag
      particle(vang,pnum) = pvang
    enddo
  end subroutine repel

  subroutine colortemp(val_min,val_max)
    real val_min,val_max,rgb_bins(5),bin_size,my_val,&
           bin_min,bin_max,bin_sfact,my_rgb(3)
    integer i,j,use_bin
    logical in_bin
    !divide scale range into four bins (five values)
    if((val_min-val_max) >= 0.0)then
      val_min = 0.0
      val_max = 0.001
    endif
    bin_size = (val_max-val_min)/4.0d0
    rgb_bins(1) = val_min
    do i = 2,5
      rgb_bins(i) = val_min + bin_size*real(i-1,8)
    enddo
    ! loop over the solution value at each node and generate
    ! a color value from the bins
    do i = 1,ndropped
      in_bin = .false.
      use_bin = 0
      my_val = 1.0-particle(ptem,i)
      ! check the min and max values first (out of range)
      if(my_val < val_min)then
        in_bin = .true.
        my_rgb(1) = 0.0
        my_rgb(2) = 0.0
        my_rgb(3) = 1.0
      elseif(my_val > val_max)then
        in_bin = .true.
        my_rgb(1) = 1.0
        my_rgb(2) = 0.0
        my_rgb(3) = 0.0
      elseif(isnan(my_val))then
        in_bin = .true.
        my_rgb(1) = 1.0
        my_rgb(2) = 0.0
        my_rgb(3) = 0.0
      else
        use_bin = 1
        in_bin = .false.
      endif
      ! find the bin and calculate the color scaling factor
      do while(.not.in_bin)
        bin_min = rgb_bins(use_bin)
        bin_max = rgb_bins(use_bin+1)
        !print *,"bin_min=",bin_min," bin_max=",bin_max," use_bin=",use_bin
        if(my_val <= bin_max .and. my_val >= bin_min)then
          bin_sfact = (my_val-bin_min)/(bin_max-bin_min)
          in_bin = .true.
        else
          use_bin = use_bin + 1
          if(use_bin > 5)stop
        endif
      enddo
      ! apply the scaling factor to the appropriate value for the bin
      if(use_bin == 1)then  ! bin 0-1
        my_rgb(1) = 1.0-bin_sfact
        my_rgb(2) = 1.0-bin_sfact
        my_rgb(3) = 1.0
      elseif(use_bin == 2)then ! bin 1-2
        my_rgb(1) = bin_sfact
        my_rgb(2) = 0.0 !bin_sfact
        my_rgb(3) = 1.0-bin_sfact
      elseif(use_bin == 3)then   ! bin 2-3
        my_rgb(1) = 1.0
        my_rgb(2) = bin_sfact
        my_rgb(3) = 0.0
      elseif(use_bin == 4)then  ! bin 3-4
        my_rgb(1) = 1.0-bin_sfact
        my_rgb(2) = 1.0-bin_sfact
        my_rgb(3) = 0.0
      endif
      ! set the color value for the particle 
      if(particle(ptem,i) < 0.02)then
        pointcolor(1,i) = 0.3
        pointcolor(2,i) = 0.3
        pointcolor(3,i) = 0.3
      else
        pointcolor(1,i) = min(pointcolor0(1,i)+my_rgb(1),1.0)
        pointcolor(2,i) = min(pointcolor0(2,i)+my_rgb(2),1.0)
        pointcolor(3,i) = min(pointcolor0(3,i)+my_rgb(3),1.0)
      endif
      pointcolor(4,i) = 1.0 !min(particle(ptem,i)+0.7,1.0)
    enddo
  end subroutine colortemp

! since this is applied to all points on every time step
! it seems like a good place to impose a terminal velocity...
  subroutine applygravity()
    real pvy,pvx,pvmag,pvang,dvx,dvy
    integer i
    select case (screen1%rotation)
      case (0)
        dvy = -gravity*dt*accely
        dvx = -gravity*dt*accelx
      case (1)
        dvy = -gravity*dt*accelx
        dvx = gravity*dt*accely
      case (2)
        dvy = gravity*dt*accely
        dvx = gravity*dt*accelx
      case (3)
        dvy = gravity*dt*accelx
        dvx = -gravity*dt*accely
    end select
    do i = 1,ndropped
      ! calculate the current vector
      pvmag = particle(vmag,i)
      pvang = particle(vang,i)
      pvx = pvmag*cos(pvang)
      pvy = pvmag*sin(pvang)
      ! calculate gravity based on default screen rotation
      pvy = pvy + dvy
      pvx = pvx + dvx
      ! re-calculate the new vector
      pvmag = sqrt(pvx**2+pvy**2)
      if(pvmag > pvmax) pvmag = pvmax ! there it is!
      pvang = atan2(pvy,pvx)
      particle(vmag,i) = pvmag
      particle(vang,i) = pvang
      !particle(vx,i) = pvx
      !particle(vy,i) = pvy
    enddo
  end subroutine applygravity

end module effects
  
