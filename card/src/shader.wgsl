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
    @location(2) dot: f32,
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
    out.normal = mat3x3<f32>(
        matrix[0].xyz,
        matrix[1].xyz,
        matrix[2].xyz
        ) * model.normal;
    out.dot = dot(out.normal, model.normal);
    out.clip_position = matrix * vec4<f32>(model.position, 1.0);
    return out;
}

//conversion from linear srgb to oklab colorspace
fn lrgb2oklab(ori_col:vec3<f32>) -> vec3<f32> {
    let lrgb2cone = mat3x3<f32>(
        vec3<f32>(0.412165612, 0.211859107, 0.0883097947),
        vec3<f32>(0.536275208, 0.6807189584, 0.2818474174),
        vec3<f32>(0.0514575653, 0.107406579, 0.6302613616),
    );
    var col = ori_col * lrgb2cone;
    col = pow(col, vec3<f32>(1.0 / 3.0));
    let cone2lab = mat3x3<f32>(
        vec3<f32>(0.2104542553, 1.9779984951, 0.0259040371),
        vec3<f32>(0.7936177850, -2.4285922050, 0.7827717662),
        vec3<f32>(0.0040720468, 0.4505937099, -0.8086757660),
    );
    col = col*cone2lab;
    return col;
}

//conversion from oklab to linear srgb
fn oklab2lrgb(ori_col:vec3<f32>) -> vec3<f32> {
    let cone2lrgb = mat3x3<f32>(
        vec3<f32>(1, 1, 1),
        vec3<f32>(0.3963377774, -0.1055613458, -0.0894841775),
        vec3<f32>(0.2158037573, -0.0638541728, -1.2914855480),
    );

    var col = ori_col*cone2lrgb;
    col = col * col * col;
    let lab2cone = mat3x3<f32>(
        vec3<f32>(4.0767416621, -1.2684380046, -0.0041960863),
        vec3<f32>(-3.3077115913, 2.6097574011, -0.7034186147),
        vec3<f32>(0.2309699292, -0.3413193965, 1.7076147010),
    );
    col = col*lab2cone;
    return col;
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

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    var color: vec4<f32> = textureSample(t_diffuse, s_diffuse, in.tex_coords);
    var dim = vec2<f32>(textureDimensions(t_diffuse, 0));
    if (color.a < 0.1) {
        discard;
    }
    if (in.dot < 0.1) {
        return vec4<f32>(vec3<f32>(0.5), 1.0)*color;
    }
    let coord = in.clip_position.xy; // in.tex_coords*dim;
    if (in.dot < 0.2) {
        if (!(coord.x%2.0 < 1.0 && coord.y%2.0 < 1.0)) {
            return vec4<f32>(vec3<f32>(0.5), 1.0)*color;
        }
    } else if (in.dot < 0.3) {
        if (coord.x%2.0 < 1.0 == coord.y%2.0 < 1.0) {
            return vec4<f32>(vec3<f32>(0.5), 1.0)*color;
        }
    } else if (in.dot < 0.4) {
        if (coord.x%2.0 < 1.0 && coord.y%2.0 < 1.0) {
            return vec4<f32>(vec3<f32>(0.5), 1.0)*color;
        }
    }

    var pos = vec2<f32>(in.normal.x,in.normal.y)*1.0;
    if (pos.x > 2.0 || pos.x < -2.0) {
        pos -= sign(pos.x)*vec2<f32>(4.0,0.0);
        if (on_line(0.7853, pos+.5, 0.03, in.tex_coords.x, in.tex_coords.y)) {
            return vec4<f32>(color.xyz*10.0,1.0);
        }
    }

    return color; //vec4<f32>(vec3<f32>(in.dot), 1.0);
}