module gl_fortran

USE ISO_C_BINDING
use iso_c_utilities
use opengl_gl
use shared_data
use gl_2es
real scolor1,scolor2,scolor3,sposx,sposy
integer(GLenum) glerrorcode
character*20 glerrorstring
character*1024 infoLog
character glinfo*1024
integer(Gluint)vertex_shader,frag_shader,shader_program,logLength

contains

subroutine dust_engine_initgl() bind(c)
  integer psrange(1)
  integer(GLint), dimension(1) :: ivparams
  character*1024 vert_source,frag_source,infoLog
  !call omp_set_num_threads(1)
  write(10,*)"dust_engine_initgl called..."
  write(10,*)"glClearColor.. ",glerror_string()
  flush(10)
  call glClearColor(0.0, 0.0, 0.0, 1.0)
  call glEnable(GL_BLEND)
  call glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA)
  call glViewport(0,0,width,height)
  vfact = 1.0
  ! set up resources
  allocate(gl2%vertex_buffer(2))
  allocate(gl2%color_buffer(2))
  call glGenBuffers(2,gl2%vertex_buffer)
  call glGenBuffers(2,gl2%color_buffer)
  ! vertex buffer is now assigned.. fill with data later
  ! compile shaders
  vert_source = "s1.v.glsl"//c_null_char
  frag_source = "s1.f.glsl"//c_null_char
  gl2%vert_shader = make_shader(GL_VERTEX_SHADER,vert_source)
  gl2%frag_shader = make_shader(GL_FRAGMENT_SHADER,frag_source)
  gl2%sprogram = make_program(gl2%vert_shader,gl2%frag_shader)
  gl2%attributes%gposition = glGetAttribLocation(gl2%sprogram,'position'//c_null_char)
  gl2%attributes%pcolor = glGetAttribLocation(gl2%sprogram,'pcolor'//c_null_char)
  gl2%uniforms%psize = glGetUniformLocation(gl2%sprogram,'psize'//c_null_char)
  ! set up the ui overlay resources
  allocate(gl3%vertex_buffer(1))
  call glGenBuffers(1,gl3%vertex_buffer)
  vert_source = "ui.v.glsl"//c_null_char
  frag_source = "ui.f.glsl"//c_null_char
  gl3%vert_shader = make_shader(GL_VERTEX_SHADER,vert_source)
!  write(10,*)"gl2%vert_shader = ",gl2%vert_shader," glErrorCode = ",glerror_string()
  gl3%frag_shader = make_shader(GL_FRAGMENT_SHADER,frag_source)
!  write(10,*)"gl2%frag_shader = ",gl2%frag_shader," glErrorCode = ",glerror_string()
!  write(10,*)".. callfing make_program : "
  gl3%sprogram = make_program(gl3%vert_shader,gl3%frag_shader)
  gl3%attributes%gposition = glGetAttribLocation(gl3%sprogram,'position'//c_null_char)
  gl3%uniforms%offset = glGetUniformLocation(gl3%sprogram,'offset'//c_null_char)
  gl3%uniforms%button = glGetUniformLocation(gl3%sprogram,'button'//c_null_char)
  gl3%uniforms%screen = glGetUniformLocation(gl3%sprogram,'screen'//c_null_char)
  gl3%uniforms%texture = glGetUniformLocation(gl3%sprogram,'textures[0]'//c_null_char)
! load the overlay texture
  gl3%texture = make_soil_texture("overl1.png")
  call glBindBuffer(GL_ARRAY_BUFFER,gl3%vertex_buffer(1))
  buffsize = sizeof(overlay)
  call glBufferData(GL_ARRAY_BUFFER,buffsize,&
                    c_loc(overlay),GL_STATIC_DRAW)
  write(10,*)'ui_texture = ',gl3%texture
  flush(10)
  write(10,*)"dust_engine_initgl completed... glErrorCode = ",glerror_string()
  flush(10)
end subroutine dust_engine_initgl

subroutine glclearbuffer()
  call glClear(ior(GL_COLOR_BUFFER_BIT,GL_DEPTH_BUFFER_BIT))
end subroutine glclearbuffer

subroutine drawarrays()
  integer i
  real scalex,scaley
  scalex = float(width)/2.0
  scaley = float(height)/2.0
  ! load a temporary array with data for the vertex buffer object
  ! use the shadowxy array for now to scale to the screen dimensions
  do i = 1,ndropped
      shadowxy(:,i) = (/(-1.0+((particle(x,i)+camera_dx)/scalex)),&
                      (1.0-((particle(y,i)+camera_dy)/scaley))/)
  enddo
  call glUseProgram(gl2%sprogram)
  ! set the point size
  call glUniform1f(gl2%uniforms%psize,psize)
  ! feed the array buffer for position
  call glBindBuffer(GL_ARRAY_BUFFER,gl2%vertex_buffer(1))
  buffsize = sizeof(shadowxy)
  call glBufferData(GL_ARRAY_BUFFER,buffsize,&
                    c_loc(shadowxy),GL_STATIC_DRAW)
  call glVertexAttribPointer(&
    gl2%attributes%gposition,&
    2, &
    GL_FLOAT, &
    GL_FALSE, &
    0, &
    c_null_ptr);
  call glEnableVertexAttribArray(gl2%attributes%gposition);
  call glBindBuffer(GL_ARRAY_BUFFER,0)
  ! feed the array buffer for color
  call glBindBuffer(GL_ARRAY_BUFFER,gl2%color_buffer(1))
  buffsize = sizeof(pointcolor)
  call glBufferData(GL_ARRAY_BUFFER,buffsize,&
                    c_loc(pointcolor),GL_STATIC_DRAW)
  call glVertexAttribPointer(&
    gl2%attributes%pcolor,&
    4, &
    GL_FLOAT, &
    GL_FALSE, &
    0, &
    c_null_ptr);
  call glEnableVertexAttribArray(gl2%attributes%pcolor);
  call glBindBuffer(GL_ARRAY_BUFFER,0)
  ! draw the points
  call glDrawArrays(GL_POINTS,0,ndropped)
end subroutine drawarrays

subroutine gl_draw_ui()
    integer i
  real scalex,scaley
  scalex = float(width)/2.0
  scaley = float(height)/2.0
  ! load a temporary array with data for the vertex buffer object
  ! use the shadowxy array for now
  do i = 1,ui_ptn
      shadowxy(:,i) = (/(-1.0+((ui_text(x,i)+camera_dx)/scalex)),&
                      (1.0-((ui_text(y,i)+camera_dy)/scaley))/)
  enddo
  call glUseProgram(gl2%sprogram)
  ! feed the array buffer for position
  call glUniform1f(gl2%uniforms%psize,4.0)
  call glBindBuffer(GL_ARRAY_BUFFER,gl2%vertex_buffer(2))
  buffsize = ui_ptn*2*sizeof(GLfloat)
  call glBufferData(GL_ARRAY_BUFFER,buffsize,&
                    c_loc(shadowxy),GL_STATIC_DRAW)
  call glVertexAttribPointer(&
    gl2%attributes%gposition,&
    2, &
    GL_FLOAT, &
    GL_FALSE, &
    0, &
    c_null_ptr);
  call glEnableVertexAttribArray(gl2%attributes%gposition);
  call glBindBuffer(GL_ARRAY_BUFFER,0)
  ! feed the array buffer for color
  call glBindBuffer(GL_ARRAY_BUFFER,gl2%color_buffer(2))
  buffsize = ui_ptn*4*sizeof(GLfloat)
  call glBufferData(GL_ARRAY_BUFFER,buffsize,&
                    c_loc(ui_color),GL_STATIC_DRAW)
  call glVertexAttribPointer(&
    gl2%attributes%pcolor,&
    4, &
    GL_FLOAT, &
    GL_FALSE, &
    0, &
    c_null_ptr);
  call glEnableVertexAttribArray(gl2%attributes%pcolor);
  call glBindBuffer(GL_ARRAY_BUFFER,0)
  ! draw the points
  call glDrawArrays(GL_POINTS,0,ui_ptn)
end subroutine gl_draw_ui

subroutine draw_ui_overlay()
!  write(10,*)"drawing overlay.."
!  flush(10)
  if(menu_on)then
    if(menu_xslide > menu_xmin)then
      menu_xslide = menu_xslide - dt*5.0*(menu_xslide*1.1-menu_xmin)
      menu_moving = .true.
    elseif(menu_xslide < menu_xmin)then
      menu_xslide = menu_xmin
      menu_moving = .true.
    else
      menu_moving = .false.
    endif
  else
    if(menu_xslide < 1.0)then
      menu_xslide = menu_xslide + dt*5.0*(1.1-menu_xslide)
      menu_moving = .true.
    elseif(menu_xslide > 1.0)then
      menu_xslide = 1.0
      menu_moving = .true.
    else
      menu_moving = .false.
    endif
  endif
  call glBindBuffer(GL_ARRAY_BUFFER,gl3%vertex_buffer(1))
  call glUseProgram(gl3%sprogram);
  call glActiveTexture(GL_TEXTURE0);
  call glBindTexture(GL_TEXTURE_2D, gl3%texture);
  call glUniform1i(gl3%uniforms%texture, 0);
  call glUniform1f(gl3%uniforms%offset,menu_xslide)
  call glUniform2f(gl3%uniforms%screen,float(width),float(height))
  call glUniform1iv(gl3%uniforms%button,7,c_loc(menu_button))
  call glEnableVertexAttribArray(gl3%attributes%gposition);
  call glVertexAttribPointer(&
    gl3%attributes%gposition,&
    2, &
    GL_FLOAT, &
    GL_FALSE, &
    0, &
    c_null_ptr);
  ! draw the textured overlay square
  call glDrawArrays(GL_TRIANGLE_STRIP,0,4)
end subroutine draw_ui_overlay

subroutine shutdown()
    write(10,*)
    write(10,*)"total frames = ",totalframes," ttotal = ",ttotal
    write(10,*)"Average FPS = ",totalframes/ttotal
    flush(10)
    call exit(0)
end subroutine shutdown

character*30 function glerror_string()
  integer errno
  errno = glGetError()
  write(glerror_string,'(a,i4)')"Unknown error code: ",errno
  if(errno == 0)glerror_string = "GL_NO_ERROR"
  if(errno == 1280)glerror_string = "GL_INVALID_ENUM"
  if(errno == 1281)glerror_string = "GL_INVALID_VALUE"
  if(errno == 1282)glerror_string = "GL_INVALID_OPERATION"
  if(errno == 1285)glerror_string = "GL_OUT_OF_MEMORY"
end function glerror_string

end module gl_fortran
