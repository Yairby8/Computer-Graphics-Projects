# 🎨 Computer Graphics Projects

A collection of four GPU and rendering projects built from the ground up — covering the full spectrum from skeletal animation and mesh geometry to procedural shaders and real-time ray tracing. All implemented in **Unity** with **C#** and **HLSL/Cg**.

---

## 📂 Projects

| Project | Description |
|---------|-------------|
| [**Skeletal Animation**](./skeletal-animation) | BVH motion capture playback with forward kinematics, custom quaternion math, and SLERP interpolation |
| [**Mesh Processing**](./mesh-processing) | OBJ mesh loading with per-vertex normal computation, flat and smooth shading from scratch |
| [**Shader Programming**](./shader-programming) | GPU vertex/fragment shaders for Perlin noise, bump mapping, animated water, and environment reflections |
| [**Ray Tracing**](./ray-tracing) | Real-time compute shader ray tracer with recursive reflections, Snell's law refraction, and shadow casting |

---

## 🛠️ Tech Stack

- **Engine:** Unity
- **Languages:** C#, HLSL/Cg
- **Rendering:** Custom shaders, compute shaders, forward kinematics pipeline
- **Math:** Manual implementations of matrix transforms, quaternions, SLERP, Perlin noise, ray-geometry intersections

---

## 🚀 Getting Started

Each project is a self-contained Unity project. To run any of them:

1. Open Unity Hub
2. Click **Add** and select the desired project folder
3. Open the project and load the main scene
4. Press Play

---

## 🖼️ Highlights

- **Skeletal Animation** — Parses real motion capture data (BVH) and drives a skeleton in real time using hand-rolled quaternion SLERP
- **Mesh Processing** — Computes smooth and flat shading from raw triangle data with per-vertex normal averaging
- **Shader Programming** — Animated ocean surface with multi-octave Perlin noise displacement and cube-map Fresnel reflections, all on the GPU
- **Ray Tracing** — Full ray tracer on the GPU with recursive bouncing, refraction through glass, hard shadows, and animated scenes

---

## 📄 License

This repository contains projects developed for educational and portfolio purposes.
