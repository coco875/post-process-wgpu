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

@group(0) @binding(0)
var t_diffuse: texture_2d<f32>;
@group(0) @binding(1)
var s_diffuse: sampler;

@group(0) @binding(2)
var t_depth: texture_depth_2d;

fn blur(size_blur: i32, tex_coords: vec2<f32>) -> vec4<f32> {

    var color : vec4<f32> = textureSample(t_diffuse, s_diffuse, tex_coords);
    let dimensions = textureDimensions(t_diffuse);

    var count: i32 = 1;

    for (var x : i32 = -size_blur; x <= size_blur; x++) {
        for (var y : i32 = -size_blur; y <= size_blur; y++) {
            var offset: vec2<f32> = vec2<f32>(f32(x)/f32(dimensions.x), f32(y)/f32(dimensions.y));
            color += textureSample(t_diffuse, s_diffuse, tex_coords + offset);
            count += 1;
        }
    }

    color /= f32(count);
    return color;
}

fn smoothstep(edge0:f32, edge1:f32, x:f32) -> f32 {
   // Scale, and clamp x to 0..1 range
   let r = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);

   return r * r * (3.0 - 2.0 * r);
}

const min_depth = 0.315;
const max_depth = 0.320;
const intensity = 10.0;
const smooth_size = 0.02;

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {

    let pixel_depth: f32 = textureSample(t_depth, s_diffuse, in.tex_coords);
    var blur_level = 0.0;

    // if (pixel_depth < min_depth) {
    //     blur_level = (min_depth - pixel_depth);//*intensity;
    // } else if (pixel_depth > max_depth) {
    //     blur_level = (pixel_depth - max_depth);//*intensity);
    // }

    blur_level = smoothstep(max_depth, max_depth+smooth_size, pixel_depth)*smoothstep(min_depth, min_depth+smooth_size, pixel_depth);

    let color: vec4<f32> = vec4<f32>(blur_level, blur_level, blur_level, 1.0);
    //let color: vec4<f32> = blur(i32(blur_level*intensity), in.tex_coords);
    return color;
}