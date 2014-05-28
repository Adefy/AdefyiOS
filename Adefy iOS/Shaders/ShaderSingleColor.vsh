attribute vec3 Position;

uniform mat4 Projection;
uniform mat4 ModelView;
uniform int Layer;

void main() {
  gl_Position = Projection * ModelView * vec4(Position.xy, Layer, 1);
}