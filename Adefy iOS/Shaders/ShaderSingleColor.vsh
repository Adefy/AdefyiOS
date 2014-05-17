attribute vec3 Position;

uniform mat4 Projection;
uniform mat4 ModelView;
uniform int Layer;

void main() {
  mat4 mvp = Projection * ModelView;
  gl_Position = mvp * vec4(Position.xy, Layer, 1);
}