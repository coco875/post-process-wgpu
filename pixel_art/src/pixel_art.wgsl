// Vertex shader

struct VertexInput {
    @location(0) position: vec3<f32>,
    @location(1) tex_coords: vec2<f32>,
}

struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
    @location(0) tex_coords: vec2<f32>,
}

@vertex
fn vs_main(
    model: VertexInput,
) -> VertexOutput {
    var out: VertexOutput;
    out.tex_coords = model.tex_coords;
    out.clip_position = vec4<f32>(model.position, 1.0);
    return out;
}

fn get_position(tex_coords: vec2<f32>, dimensions: vec2<u32>) -> vec2<i32> {
    return vec2<i32>(i32(tex_coords.x * f32(dimensions.x)), i32(tex_coords.y * f32(dimensions.y)));
}

fn set_position(tex_coords: vec2<f32>, dimensions: vec2<u32>, position: vec2<i32>) -> vec2<f32> {
    return vec2<f32>(f32(position.x) / f32(dimensions.x), f32(position.y) / f32(dimensions.y));
}

@group(0) @binding(0)
var t_diffuse: texture_2d<f32>;
@group(0) @binding(1)
var s_diffuse: sampler;

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    var position = get_position(in.tex_coords, textureDimensions(t_diffuse));
    // position = position / 8 * 8;
    position &= ~vec2<i32>(7); // round down to multiple of 8
    var position_f = set_position(in.tex_coords, textureDimensions(t_diffuse), position);
    let color = textureSample(t_diffuse, s_diffuse, position_f);
    return color;
}