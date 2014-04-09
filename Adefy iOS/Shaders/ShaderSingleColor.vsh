attribute vec3 Position;

uniform mat4 Projection;
uniform mat4 ModelView;

void main() {
  mat4 mvp = Projection * ModelView;
  gl_Position = mvp * vec4(Position.xyz, 1);
 }