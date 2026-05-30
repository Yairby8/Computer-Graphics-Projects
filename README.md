# 🎨 Computer Graphics

A collection of four projects exploring core computer graphics concepts — from skeletal animation and mesh processing to GPU shader programming and real-time ray tracing. All projects are built in **Unity** using **C#** and **HLSL/Cg**.

---

## 📂 Projects

| # | Project | Topic |
|---|---------|-------|
| 1 | [Skeletal Animation & Forward Kinematics](./ex1) | BVH parsing, quaternion math, SLERP interpolation |
| 2 | [Mesh Processing & Shading](./ex2) | OBJ loading, normal calculation, flat vs. smooth shading |
| 3 | [GPU Shader Programming](./ex3) | Procedural noise, bump mapping, Blinn-Phong, water simulation |
| 4 | [GPU Ray Tracing](./ex4) | Compute shader ray tracer, reflections, refractions, shadows |

---

## 🛠️ Tech Stack

- **Engine:** Unity
- **Languages:** C#, HLSL/Cg
- **Rendering:** Custom shaders, compute shaders, forward kinematics
- **Math:** Manual implementations of matrix transforms, quaternions, SLERP, Perlin noise

---

## 🚀 Getting Started

Each project is a self-contained Unity project. To run any exercise:

1. Open Unity Hub
2. Click **Add** and select the desired exercise folder (e.g., `ex1/`)
3. Open the project and load the main scene

---

## 🖼️ Highlights

- **Exercise 1** — Parses real motion capture data (BVH) and animates a skeleton in real time using custom quaternion SLERP
- **Exercise 2** — Implements smooth and flat shading from scratch with per-vertex normal averaging
- **Exercise 3** — Writes GPU shaders for animated water with Perlin noise displacement and cube-map reflections
- **Exercise 4** — A full ray tracer running on the GPU with recursive reflections, Snell's law refraction, and shadow casting

---

## 📄 License

This repository contains coursework projects for educational purposes.
