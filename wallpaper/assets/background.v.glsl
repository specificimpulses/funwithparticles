attribute vec2 position;
uniform mediump vec2 offset;
uniform mediump vec2 swipescale;
uniform mediump vec2 swipeoverlap;
varying vec2 texcoord;
void main()
{
    gl_Position = vec4(position.x,position.y, 0.0, 1.0);
    texcoord = swipescale*(position * vec2(0.5) + vec2(0.5))+
               swipeoverlap*offset;
    //texcoord.x = texcoord.x+offset.x;
    //texcoord.y = texcoord.y+offset.y;
    //texcoord = -position;
}