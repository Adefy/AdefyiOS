attribute vec3 Position;
attribute vec2 aTexCoord;
attribute vec2 aUVScale;

uniform mat4 Projection;
uniform mat4 ModelView;

varying highp vec2 vTexCoord;

void main() {
  gl_Position = Projection * ModelView * vec4(Position.xyz, 1);
  vTexCoord = aTexCoord * aUVScale;
}