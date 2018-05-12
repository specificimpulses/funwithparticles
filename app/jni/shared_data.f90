module shared_data
  USE ISO_C_BINDING
  use opengl_gl
  type(c_ptr) fortran_app
  real(GLfloat), allocatable :: particle(:,:)
  real(GLfloat), allocatable, target :: pointxy(:,:),pointcolor(:,:),pointcolor0(:,:)
  real(GLfloat), allocatable, target :: shadowxy(:,:),elbuffer(:)
  integer, target :: zero_ptr
  integer(GLsizei) buffsize
  integer nparticles,ndropped,firstpass,npulled
  real droptimer,fps,framecount,engine_in_ave,pulldt
  real bminx,bmaxx,bminy,bmaxy,ttotal,totalframes
  real dt,touch_pressure,psize,dm_size,fpstimer,avefps
  integer time0,time1,start_time,realtimer,engine_timer(2)
  integer ticks_in,ticks_out
  integer*4 :: count_rate, count_max
  !real width,height,psized
  integer width,height,rotation,xmax,ymax,touch_action
  integer :: debug = 0
  real viewangle,vfact,zdist,reset
  real, parameter :: d2r = 57.29577951
  real, parameter :: pi = 3.141592654
  INTEGER mouse_x,mouse_y,mouse_x0,mouse_y0
  integer mtouch_x(8),mtouch_y(8),mtouch_x0(8),mtouch_y0(8),mtouch_action(8)
  real mtouch_pressure(8)
  integer mtouch_npointers
  logical :: mtouch_down(8) = .false.
  real mouseoff_x,mouseoff_y,accelx0,accely0,accelz0
  logical mouse1down,mouse2down,mouse3down
  real accelx,accely,accelz,camera_dx,camera_dy
  ! define storage for the dot matrix font definitions
  integer, allocatable :: dmfont(:,:) ! (char,row,col)
  integer nui_chars,nui_pts,ui_ptn,message,nmessages
  integer :: textdropped = 0
  real    :: textdroptimer = 0.0
  real    :: textdroptime = 0.01
  real    :: textontimer = 0.0
  real, allocatable, target :: ui_text(:,:), ui_color(:,:)
  real    :: button_delay = 0.0
  logical :: nparticles_select = .true.
  logical :: nparticles_selected = .false.
  real    :: nparticles_selected_timer = 3.0
  logical :: alldropped = .false.
  logical :: touch_on = .false.
  logical :: drawtext = .false.
  logical :: textloop = .false.
  integer :: stopcount = 0
  real swipex(2),swipey(2)
  real :: touchdelay = 0.0
  real spiralfactor
  real :: bench_time = 0.0
  character*500 messages(100)
  real(GLfloat), target :: overlay(2,4)
  integer :: key_num = 0
  logical :: key_down = .false.
  logical :: touch_down = .false.
  logical :: touch_override = .false.
  logical :: menu_on = .false.
  logical :: menu_moving = .false.
  logical :: attract_on = .false.
  logical :: repel_on = .false.
  logical :: show_fps = .false.
  logical :: gravity_on = .false.
  logical :: collision_on = .false.
  logical :: swirl_on = .false.
  logical :: credits_on = .false.
  logical :: credits_running = .false.
  logical :: benchmark_on = .false., benchmark_start = .false.
  logical :: benchmark_done = .false.
  logical :: start_message = .true.
  real :: benchmark_time = 0.0, benchmark_fps = 0.0
  real :: benchmark_x = 0.0, benchmark_y = 0.0
  real :: menu_xslide = 1.0
  real :: menu_xmin = 0.78
  real :: ui_delay = 0.0, swirl_angle = 0.0
  real :: pvmax
  integer :: text_delay = 5.0
  integer, target :: menu_button(7) = 0
  integer :: benchmark_frames = 0
  type g_uniforms
    integer(GLint) :: psize,texture,offset,button,screen
  end type g_uniforms

  type g_attributes
    integer(GLint) :: gposition,pcolor
  end type g_attributes

  type g_resources
    integer(GLuint) :: element_buffer, sprogram,&
                             vert_shader, frag_shader, texture
    integer(GLuint), allocatable :: vertex_buffer(:), color_buffer(:)
    type(g_uniforms)      :: uniforms
    type(g_attributes)    :: attributes
  end type g_resources

  ! Set global parameters for the engine
  integer, parameter ::   x = 1                ! index for x position
  integer, parameter ::   y = 2                ! index for y position
  integer, parameter ::   vmag = 3             ! index for velocity vector magnitude
  integer, parameter ::   vang = 4             ! index for velocity vector angle
  integer, parameter ::   ptem = 5             ! index for particle temperature
  integer, parameter ::   vx = 6               ! index for particle x velocity
  integer, parameter ::   vy = 7               ! index for particle y velocity
  integer, parameter ::   ax = 8               ! index for particle x acceleration
  integer, parameter ::   ay = 9               ! index for particle y acceleration
!  integer, parameter ::   nparticles = 400     ! number of points
  real,    parameter ::   gravity = 60.0      ! gravity in pixels/second^2
  real,    parameter ::   walldamp = 0.5       ! wall collision momentum dissipation
  real,    parameter ::   partdamp = 1.0       ! particle collision momentum dissipation
  real,    parameter ::   dtmin = 0.001         ! smallest value allowed for dt
  real,    parameter ::   dtmax = 0.05         ! largest value allowed for dt
  real,    parameter ::   pulltimer = 0.005     ! update time for touch pull routine
  real,    parameter ::   droptime = 0.005      ! how often to release new particles
  real,    parameter ::   bounce = 1.0         ! particle restitution factor
! build derived types for objects to be used
  type(g_resources) :: gl2, gl3
contains

  subroutine init_statics
! initialize the static variables
    nparticles = 400
    xmax = width
    ymax = height
    pvmax = float(width)*1.0
    psize = 8.5         ! intial point size
    firstpass = 1
    ndropped = 0
    dustbin = 0
    time0 = 0.0
    time1 = 0.0
    ttotal = 0.0
    droptimer = droptime
    fpstimer = 0.0
    fps = 0.0
    totalframes = 0.0
    touch_pressure = 0.0
    mouseoff_x = 0.0
    mouseoff_y = 0.0
    reset = 0.0
    nui_chars = 250
    zero_ptr = 0
    camera_dx = 0.0
    camera_dy = 0.0
    npulled = 0
    pulldt = 0.0
    swipex = 0.0
    swipey = 0.0
    nmessages = 7
    message = 1
    messages = ""
    messages(1) = "Specific Impulses"
    messages(2) = "and HMMM(mm) Games\   Present..."
    messages(3) = "Fun With\Particles"
    messages(4) = "Powered By\ FORTRAN"
    messages(7) = "For Carisa, Brodie\    and Elisa"
    messages(5) = trim(adjustl(messages(5)))
    messages(6) = "FPS"
    !messages(8) = "Press MENU Button\ For Options"
  end subroutine init_statics

  ! Setup all of the variable arrays
  subroutine init_arrays
    integer i
    real tmpr,tmpg,tmpb,tmpa
    real tmpx,tmpy,xfact,yfact
    print *,"allocating particle(",nparticles*3,",",12,")"
    if(.not.allocated(particle))allocate(particle(9,nparticles*3))
    print *,"allocating pointxy(",nparticles*3,",",2,")"
    if(.not.allocated(pointxy))allocate(pointxy(2,nparticles*3))
    if(.not.allocated(shadowxy))allocate(shadowxy(2,nparticles*3))
    !if(.not.allocated(shadowxy))allocate(shadowxy(2,5))
    if(.not.allocated(pointcolor))allocate(pointcolor(4,nparticles*3))
    if(.not.allocated(pointcolor0))allocate(pointcolor0(4,nparticles*3))
    if(.not.allocated(ui_text))allocate(ui_text(2,nui_chars*15))
    if(.not.allocated(ui_color))allocate(ui_color(4,nui_chars*15))
    ui_color = 1.0
    ! build the overlay vertex array
    overlay(:,1) = (/-1.0,-1.0/)
    overlay(:,2) = (/1.0,-1.0/)
    overlay(:,3) = (/-1.0,1.0/)
    overlay(:,4) = (/1.0,1.0/)
    do i = 1,nparticles*3
      tmpr = 0.6+rand()*0.4
      tmpg = 0.2+rand()*0.8
      tmpb = 0.2+rand()*0.8
      tmpa = 1.0 !0.1+rand()*0.9
      !pointcolor = 0.5
      pointcolor0(1,i) = 0.3
      pointcolor0(2,i) = 0.3
      pointcolor0(3,i) = 0.3
      pointcolor0(4,i) = 1.0
      xfact = -(rand()*2.0)+1.0
      yfact = -(rand()*2.0)+1.0
      if(xfact <= 0.0)then
        tmpx = xfact*width
      else
        tmpx = (xfact+1)*width
      endif
      if(yfact <= 0.0)then
        tmpy = yfact*height
      else
        tmpy = (yfact+1)*height
      endif
      particle(x,i) = tmpx
      particle(y,i) = tmpy
      particle(vmag,i) = 0.0
      particle(vang,i) = 0.0
      particle(ptem,i) = 1.0
      particle(vx,i) = 0.0
      particle(vy,i) = 0.0
      particle(ax,i) = 0.0
      particle(ay,i) = 0.0
      pointxy(x,i) = 0.0
      pointxy(y,i) = 0.0
    enddo
    spiralfactor = 0.02
  end subroutine init_arrays

end module shared_data


