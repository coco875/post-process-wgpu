use cgmath::prelude::*;
use winit::{event::{ElementState, KeyEvent, WindowEvent}, keyboard::{KeyCode, PhysicalKey}};

#[rustfmt::skip]
pub const OPENGL_TO_WGPU_MATRIX: cgmath::Matrix4<f32> = cgmath::Matrix4::new(
    1.0, 0.0, 0.0, 0.0,
    0.0, 1.0, 0.0, 0.0,
    0.0, 0.0, 0.5, 0.5,
    0.0, 0.0, 0.0, 1.0,
);

#[derive(Debug)]
pub struct Camera {
    pub eye: cgmath::Point3<f32>,
    pub target: cgmath::Point3<f32>,
    pub up: cgmath::Vector3<f32>,
    pub aspect: f32,
    pub fovy: f32,
    pub znear: f32,
    pub zfar: f32,
    pub controller: CameraController,
    pub camera_uniform: CameraUniform,
    pub camera_buffer: wgpu::Buffer,
    pub camera_bind_group: wgpu::BindGroup,
}

impl Camera {
    fn build_view_projection_matrix(&self) -> cgmath::Matrix4<f32> {
        let view = cgmath::Matrix4::look_at_rh(self.eye, self.target, self.up);
        let proj = cgmath::perspective(cgmath::Deg(self.fovy), self.aspect, self.znear, self.zfar);
        proj * view
    }

    pub fn update_view_proj(&mut self) {
        self.camera_uniform.view_proj = (OPENGL_TO_WGPU_MATRIX * self.build_view_projection_matrix()).into();
    }

    pub fn process_events(&mut self, event: &WindowEvent) -> bool {
        match event {
            WindowEvent::KeyboardInput {
                event:
                    KeyEvent {
                        state,
                        physical_key: PhysicalKey::Code(keycode),
                        ..
                    },
                ..
            } => {
                let is_pressed = *state == ElementState::Pressed;
                match keycode {
                    KeyCode::Space => {
                        self.controller.is_up_pressed = is_pressed;
                        true
                    }
                    KeyCode::ShiftLeft => {
                        self.controller.is_down_pressed = is_pressed;
                        true
                    }
                    KeyCode::KeyW | KeyCode::ArrowUp => {
                        self.controller.is_forward_pressed = is_pressed;
                        true
                    }
                    KeyCode::KeyA | KeyCode::ArrowLeft => {
                        self.controller.is_left_pressed = is_pressed;
                        true
                    }
                    KeyCode::KeyS | KeyCode::ArrowDown => {
                        self.controller.is_backward_pressed = is_pressed;
                        true
                    }
                    KeyCode::KeyD | KeyCode::ArrowRight => {
                        self.controller.is_right_pressed = is_pressed;
                        true
                    }
                    _ => false,
                }
            }
            _ => false,
        }
    }

    pub fn update_camera(&mut self) {
        let forward = self.target - self.eye;
        let forward_norm = forward.normalize();
        let forward_mag = forward.magnitude();

        // Prevents glitching when camera gets too close to the
        // center of the scene.
        // if self.controller.is_forward_pressed && forward_mag > self.controller.speed {
        //     self.eye += forward_norm * self.controller.speed;
        // }
        // if self.controller.is_backward_pressed {
        //     self.eye -= forward_norm * self.controller.speed;
        // }

        let right = forward_norm.cross(self.up);
        let up = right.cross(forward_norm);

        // Redo radius calc in case the up/ down is pressed.
        let forward = self.target - self.eye;
        let forward_mag = forward.magnitude();

        if self.controller.is_right_pressed {
            // Rescale the distance between the target and eye so
            // that it doesn't change. The eye therefore still
            // lies on the circle made by the target and eye.
            self.eye = self.target - (forward + right * self.controller.speed).normalize() * forward_mag;
        }
        if self.controller.is_left_pressed {
            self.eye = self.target - (forward - right * self.controller.speed).normalize() * forward_mag;
        }

        if self.controller.is_forward_pressed {
            self.eye = self.target - (forward + up * self.controller.speed).normalize() * forward_mag;
        }
        if self.controller.is_backward_pressed {
            self.eye = self.target - (forward - up * self.controller.speed).normalize() * forward_mag;
        }
    }
}

#[repr(C)]
#[derive(Debug, Copy, Clone, bytemuck::Pod, bytemuck::Zeroable)]
pub struct CameraUniform {
    view_proj: [[f32; 4]; 4],
}

impl CameraUniform {
    pub fn new() -> Self {
        Self {
            view_proj: cgmath::Matrix4::identity().into(),
        }
    }
}

#[derive(Debug)]
pub struct CameraController {
    speed: f32,
    is_up_pressed: bool,
    is_down_pressed: bool,
    is_forward_pressed: bool,
    is_backward_pressed: bool,
    is_left_pressed: bool,
    is_right_pressed: bool,
}

impl CameraController {
    pub fn new(speed: f32) -> Self {
        Self {
            speed,
            is_up_pressed: false,
            is_down_pressed: false,
            is_forward_pressed: false,
            is_backward_pressed: false,
            is_left_pressed: false,
            is_right_pressed: false,
        }
    }
}