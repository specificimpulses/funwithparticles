module globals
    use opengl_gl
    use iso_c_binding
    implicit none
    ! values that are used a lot...
    real, parameter :: pi = 3.141592654
    real, parameter :: d2r = 57.29577951
    real :: gravity = 150.0  ! pixels/sec
    real :: attract = 0.5
    integer, parameter :: debug = 0
    logical :: paused = .false., resetparticles = .true.
    logical :: touch_enabled = .true.
    logical :: gravity_enabled = .true.
    integer ndropped
    integer nparticles
    real psize,pvmax
    ! enumerators
    integer, parameter ::   x = 1           ! index for x position
    integer, parameter ::   y = 2           ! index for y position
    integer, parameter ::   diam = 3        ! index for diameter
    integer, parameter ::   mass = 4        ! index for mass
    integer, parameter ::   rho = 5         ! index for density
    integer, parameter ::   vmag = 6        ! index for velocity vector magnitude
    integer, parameter ::   vang = 7        ! index for velocity vector angle
    integer, parameter ::   ptem = 8        ! index for velocity vector angle
    integer, parameter ::   r = 1           ! index for color red channel
    integer, parameter ::   g = 2           ! index for color green channel
    integer, parameter ::   b = 3           ! index for color blue channel
    integer, parameter ::   a = 4           ! index for color alpha channel
    integer, parameter ::   nprops = 9      ! number of properties
    real,    parameter ::   walldamp = 0.85     ! wall collision momentum dissipation
    real,    parameter ::   partdamp = 0.985    ! particle collision momentum dissipation
    ! global log string
    character*200 :: logstr = ""
    ! screen properties
    type screen
        integer(GLint) :: width = 0, height = 0, rotation = 0
        real(GLfloat) :: aspect = 0.0
    end type screen
    type(screen) screen1
    type camera
        real(GLfloat) :: zoom = 1.0, x = 0.0, y = 0.0, aspect = 1.0,&
                         pzoom = 1.0, zoom1 = 1.0, zoom_max = 0.005,&
                         zoom_min = 0.0005, dx = 0.0, dy = 0.0
        logical :: zoomin = .false.
    end type camera
    type(camera) camera1
    integer(GLuint), allocatable :: vertex_buffer(:), color_buffer(:)
    integer(GLsizei) :: buffsize = 0
    ! particle and color arrays to share with C/C++
    real(GLfloat), allocatable :: particle(:,:), pointcolor0(:,:)
    real(GLfloat), allocatable, target :: pointxy(:,:),pointcolor(:,:)
    type(c_ptr), bind(c) :: c_pointxy, c_pointcolor
end module globals
