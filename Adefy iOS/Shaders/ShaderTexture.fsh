precision highp float;

varying highp vec2 vTexCoord;
uniform sampler2D uTexture;
varying highp vec2 vUVScale;

void main() {
  vec4 baseColor = texture2D(uTexture, vTexCoord * vUVScale);
  if(baseColor.rgb == vec3(1.0, 0.0, 1.0))
    discard;
  gl_FragColor = baseColor;
}