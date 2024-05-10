// Vertex shader

struct Camera {
    view_proj: mat4x4<f32>,
}
@group(1) @binding(0)
var<uniform> camera: Camera;

struct VertexInput {
    @location(0) position: vec3<f32>,
    @location(1) tex_coords: vec2<f32>,
    @location(2) normal: vec3<f32>,
}
struct InstanceInput {
    @location(5) model_matrix_0: vec4<f32>,
    @location(6) model_matrix_1: vec4<f32>,
    @location(7) model_matrix_2: vec4<f32>,
    @location(8) model_matrix_3: vec4<f32>,
}

struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
    @location(0) tex_coords: vec2<f32>,
    @location(1) normal: vec3<f32>,
}

@vertex
fn vs_main(
    model: VertexInput,
    instance: InstanceInput,
) -> VertexOutput {
    let model_matrix = mat4x4<f32>(
        instance.model_matrix_0,
        instance.model_matrix_1,
        instance.model_matrix_2,
        instance.model_matrix_3,
    );
    var out: VertexOutput;
    out.tex_coords = model.tex_coords;
    let matrix = camera.view_proj * model_matrix;
    out.normal = model.normal;
    out.clip_position = matrix * vec4<f32>(model.position, 1.0);
    return out;
}

// Fragment shader

@group(0) @binding(0)
var t_diffuse: texture_2d<f32>;
@group(0)@binding(1)
var s_diffuse: sampler;

fn on_line(angle:f32, offset:vec2<f32>, thickness: f32, x: f32, y: f32) -> bool {
    let c = cos(angle);
    let s = sin(angle);

    let x_new = x - offset.x;
    let y_new = y - offset.y;

    let x_rot = x_new * c - y_new * s;
    return abs(x_rot) - thickness < 0.0;
}

fn produce_pos(angle:f32) -> vec2<f32> {
    let c = cos(angle);
    let s = sin(angle);
    return vec2<f32>(c, s);
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    var color: vec4<f32> = textureSample(t_diffuse, s_diffuse, in.tex_coords);
    if (color.a < 0.1) {
        discard;
    }
    if (on_line(0.0, vec2<f32>(abs(in.normal.x/3.1415),.0), 0.03, in.tex_coords.x, in.tex_coords.y)) {
        return vec4<f32>(1.0);
    }
    return vec4<f32>(in.normal, 1.0);
}