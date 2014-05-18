precision highp float;

varying highp vec2 vTexCoord;
uniform sampler2D uTexture;

void main() {
  vec4 baseColor = texture2D(uTexture, vTexCoord);
  gl_FragColor = baseColor;
}