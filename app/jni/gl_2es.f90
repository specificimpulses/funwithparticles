module gl_2es

! include all of the OpenGL 1.X stuff.. from f03gl
use iso_c_binding
use opengl_gl

! add enumerators needed for ES2

INTEGER(GLenum), PARAMETER :: GL_VERTEX_SHADER                    = z'8B31'
INTEGER(GLenum), PARAMETER :: GL_FRAGMENT_SHADER                  = z'8B30'
INTEGER(GLenum), PARAMETER :: GL_COMPILE_STATUS                   = z'8B81'
INTEGER(GLenum), PARAMETER :: GL_INFO_LOG_LENGTH                  = z'8B84'
INTEGER(GLenum), PARAMETER :: GL_SHADER_TYPE                      = z'8B4F'
INTEGER(GLenum), PARAMETER :: GL_TEXTURE0                         = z'84C0'

! set up interfaces to all of the c functions
  interface

    integer(GLuint) function make_shader(shader_type,shader_source) bind(c,name="make_shader")
      use opengl_gl
      integer(GLenum),value :: shader_type
      character(c_char) :: shader_source(*)
    end function make_shader

    integer(Gluint) function make_texture(filename) bind(c,name="make_texture")
    use opengl_gl
    character(c_char) :: filename(*)
    end function make_texture

    integer(Gluint) function make_soil_texture(filename) bind(c,name="make_soil_texture")
    use opengl_gl
    character(c_char) :: filename(*)
    end function make_soil_texture

    integer(GLuint) function make_program(vshader,fshader) bind(c,name="make_program")
      use opengl_gl
      integer(GLuint), value :: vshader
      integer(GLuint), value :: fshader
    end function make_program

    subroutine glUseProgram(shader_program) bind(c,name="glUseProgram")
      use opengl_gl 
      integer(GLuint), value :: shader_program
    end subroutine glUseProgram

    subroutine glEnableVertexAttribArray(vindex) bind(c,name="glEnableVertexAttribArray")
      use opengl_gl
      integer(GLuint), value :: vindex
    end subroutine glEnableVertexAttribArray

    integer(GLint) function glGetAttribLocation(shader_program,attribute) bind(c,name="glGetAttribLocation")
      use opengl_gl
      integer(GLuint), value :: shader_program
      character(c_char) :: attribute(*)
    end function glGetAttribLocation

    integer(GLint) function glGetUniformLocation(shader_program,attribute) bind(c,name="glGetUniformLocation")
      use opengl_gl
      integer(GLuint), value :: shader_program
      character(c_char) :: attribute(*)
    end function glGetUniformLocation

    subroutine glVertexAttribPointer(vaindex,vasize,vatype,normalized,stride,vapointer) &
      bind(c,name="glVertexAttribPointer")
      use opengl_gl
      integer(GLuint), value :: vaindex
      integer(GLint), value :: vasize
      integer(GLenum), value :: vatype
      integer(GLboolean), value :: normalized
      integer(GLsizei), value :: stride
      type(c_ptr), value :: vapointer
    end subroutine glVertexAttribPointer

    subroutine glUniform1f(uniform,uvalue) bind(c,name="glUniform1f")
      use opengl_gl
      integer(GLint), value :: uniform
      real(GLfloat), value :: uvalue
    end subroutine glUniform1f

    subroutine glUniform2f(uniform,uvalue1,uvalue2) bind(c,name="glUniform2f")
      use opengl_gl
      integer(GLint), value :: uniform
      real(GLfloat), value :: uvalue1,uvalue2
    end subroutine glUniform2f

    subroutine glUniform1i(uniform,uvalue) bind(c,name="glUniform1i")
      use opengl_gl
      integer(GLint), value :: uniform
      integer(GLint), value :: uvalue
    end subroutine glUniform1i

    subroutine glUniform1iv(uniform,ucount,uvalue) bind(c,name="glUniform1iv")
      use opengl_gl
      integer(GLint), value :: uniform
      integer(GLsizei), value :: ucount
      type(C_PTR), value :: uvalue
    end subroutine glUniform1iv

    subroutine glActiveTexture(texture) bind(c,name="glActiveTexture")
      use opengl_gl
      integer(GLenum), value :: texture
    end subroutine glActiveTexture

    subroutine glBufferData(btarget, bsize, bdata, busage) bind(C,name="glBufferData")
       use opengl_gl
       integer(GLenum), value :: btarget
       integer(GLsizei), value :: bsize
       type(C_PTR), value :: bdata                
       integer(GLenum), value :: busage 
     end subroutine glBufferData

  end interface

end module gl_2es

