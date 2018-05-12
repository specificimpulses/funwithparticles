attribute mediump vec2 position;
attribute mediump vec4 pcolor;
uniform mediump float psize;
varying mediump vec4 fcolor;
void main()
{
    gl_Position = vec4(position, 0.0, 1.0);
    gl_PointSize = psize;
    fcolor = pcolor;
}

