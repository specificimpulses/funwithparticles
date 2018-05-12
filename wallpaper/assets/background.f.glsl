uniform sampler2D textures[1];
varying mediump vec2 texcoord;
mediump vec4 colortmp0;
void main()
{
    colortmp0 = texture2D(textures[0], texcoord);
    gl_FragColor.rgba = colortmp0.rgba;
}