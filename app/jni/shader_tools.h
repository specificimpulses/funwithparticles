void printShaderInfoLog(GLuint obj);
void printProgramInfoLog(GLuint obj);
GLuint make_shader(GLenum type, const char *filename);
GLuint make_program(GLuint vertex_shader, GLuint fragment_shader);

