varying mediump vec4 fcolor;
uniform mediump float popacity;
void main()
{
  gl_FragColor = fcolor;
  mediump vec2 p = gl_PointCoord * 2.0 - vec2(1.0);
  mediump float dotpp;
  dotpp = dot(p,p);
  gl_FragColor = vec4(fcolor.rgb,popacity);
  if (dotpp > 1.0)
  discard;
}

