module collisions
  use globals
  use timers

contains

  subroutine collide_walls()
    real px,py,pvx,pvy,dx,dy,dvx,dvy,pvmag,pvang,half_psize
    integer i
    real bminx,bminy,bmaxx,bmaxy
    half_psize = psize/2.0
    bminx = half_psize
    bminy = half_psize
    bmaxx = float(screen1%width)-half_psize
    bmaxy = float(screen1%height)-half_psize
    do i = 1, ndropped
      px = particle(x,i)
      py = particle(y,i)
      pvmag = particle(vmag,i)
      pvang = particle(vang,i)
      pvx = pvmag*cos(pvang)
      pvy = pvmag*sin(pvang)
      if(px <= bminx)then  ! X boundaries
        pvx = abs(pvx*walldamp)
        px = bminx
      elseif(px >= bmaxx)then
        pvx = -abs(pvx*walldamp)
        px = bmaxx
      endif
      if(py <= bminy)then  ! Y boundaries
        pvy = abs(pvy*walldamp)  
        py = bminy
      elseif(py >= bmaxy)then
        pvy = -abs(pvy*walldamp)
        py = bmaxy
      endif
      particle(x,i) = px
      particle(y,i) = py
      particle(vmag,i) = sqrt(pvx**2+pvy**2)
      particle(vang,i) = atan2(pvy,pvx)
    enddo
  end subroutine collide_walls

  subroutine collide_points()
    !brute force.. every particle vs. every other particle at every
    !time step.. expensive, but hey, we've got Fortran power!
    real p1x,p1y,p1vx,p1vy,p2x,p2y,p2vx,p2vy,distxy,dx12,dy12,&
         ang12,ang21,dvx1,dvy1,dvx2,dvy2,dx21,dy21,av1,av2,alpha12,&
         alpha21,v1n,v1t,v2n,v2t,v1,v2,avt12,avt21,p1v2,p1v2x,p1v2y,&
         p2v2,p2v2x,p2v2y,theta1,theta2,disterr,damper,p1v1,p2v1,&
         p1fact,p2fact
    integer i,j,k
    damper = 1.0-(1.0-partdamp)
    do i = 1,ndropped-1
      do j = i+1,ndropped
        !get point1 and point2 position
        p1x = particle(x,i)
        p1y = particle(y,i)
        p2x = particle(x,j)
        p2y = particle(y,j)
        ! calculate the distance between them
        distxy = sqrt((p2x-p1x)**2+(p2y-p1y)**2)
        ! if we're below the 2x the radius of the particle.. collision!
        if(distxy <= psize)then
          disterr = ((psize-distxy)/(2.0))
          ! calculate the angle from circle 1 to circle 2 and the relative velocities
          v1  = particle(vmag,i)
          v2  = particle(vmag,j)
          av1 = particle(vang,i)
          av2 = particle(vang,j)
          ang12 = atan2(p2y-p1y,p2x-p1x)
          ang21 = atan2(p1y-p2y,p1x-p2x)
          ! calculate the collision vectors
          ! start with the angle between the velocity and the collision normal
          ! from particle 1 to particle 2
          alpha12 = av1 - ang12 
          if(alpha12 > 180./d2r)then
            alpha12 = alpha12 - 360./d2r
          elseif(alpha12 < -180./d2r)then
            alpha12 = alpha12 + 360./d2r
          endif
          avt12 = ang12 + 90./d2r
          v1n = v1 * cos(alpha12)
          v1t = v1 * sin(alpha12)
          ! from particle 2 to particle 1
          alpha21 = av2 - ang21
          if(alpha21 > 180./d2r)then
            alpha21 = alpha21 - 360./d2r
          elseif(alpha21 < -180./d2r)then
            alpha21 = alpha21 + 360./d2r
          endif
          avt21 = ang21 + 90.0/d2r
          v2n = v2 * cos(alpha21)
          v2t = v2 * sin(alpha21)
          ! calculate the new velocity vector for each circle
          ! resolve the x and y components of the two velocities
          if(abs(alpha21) <= 90.0 .or. abs(alpha12) <= 90.0)then
            !== update the position and vector for particle 1 ==!
            p1v2x = v2n*cos(ang21)+v1t*cos(avt12)
            p1v2y = v2n*sin(ang21)+v1t*sin(avt12)
            ! calculate the new velocity            
            p1v2 = sqrt(p1v2x**2.0+p1v2y**2.0)
            theta1 = atan2(p1v2y,p1v2x)
            ! store the original magnitude
            p1v1 = particle(vmag,i)
            particle(vmag,i)=p1v2*damper  ! include momentum dissipation here
            particle(vang,i)=theta1
            ! update the position and vector for particle 2
            p2v2x = v1n*cos(ang12)+v2t*cos(avt21)
            p2v2y = v1n*sin(ang12)+v2t*sin(avt21)
            ! calculate the new velocity
            p2v2 = sqrt(p2v2x**2+p2v2y**2)
            theta2 = atan2(p2v2y,p2v2x)
            ! store the original magnitude
            p2v1 = particle(vmag,j)
            particle(vmag,j)=p2v2*damper  ! include momentum dissipation here
            particle(vang,j)=theta2
            ! correct positions for overlap.. IMPORTANT!!!
            particle(x,i)=particle(x,i)+disterr*cos(ang21)
            particle(y,i)=particle(y,i)+disterr*sin(ang21)
            particle(x,j)=particle(x,j)+disterr*cos(ang12)
            particle(y,j)=particle(y,j)+disterr*sin(ang12)
            ! calculate collision magnitude for colors
            p1dmag = abs(p1v2-p1v1)
            p2dmag = abs(p2v2-p2v1)
            ! scale by maximum velocity and add to the temperature
            p1tem0 = particle(ptem,i)
            p2tem0 = particle(ptem,j)
            p1fact = (1.0-p1tem0)**2.0
            p2fact = (1.0-p1tem0)**2.0
            particle(ptem,i) = min(p1tem0+(p1dmag/pvmax)*p1fact,1.0)
            particle(ptem,j) = min(p2tem0+(p2dmag/pvmax)*p2fact,1.0)
          endif
         endif
       enddo
     enddo
  end subroutine collide_points

end module collisions


