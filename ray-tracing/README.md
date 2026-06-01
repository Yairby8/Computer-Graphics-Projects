# 💎 Ray Tracing

A real-time ray tracer running on the GPU as a Unity compute shader — featuring recursive reflections, physically-based refraction via Snell's law, hard shadow casting, and multiple geometric primitives.

---

## 🎯 Overview

This project implements a complete ray tracing renderer on the GPU. Rays are generated from camera parameters, tested against scene geometry (spheres, planes, triangles, cylinders), and shaded with Blinn-Phong lighting. The tracer supports configurable recursive bouncing for mirror reflections and physically-correct refraction through transparent materials, including total internal reflection.

---

## ✨ Key Features

- **Real-Time GPU Execution** — Compute shader dispatched per frame for interactive rendering
- **Ray-Geometry Intersections** — Sphere, plane, triangle, disk, and cylinder primitives
- **Recursive Reflections** — Configurable bounce limit for mirror-like surfaces
- **Snell's Law Refraction** — Physically-based light bending with total internal reflection handling
- **Shadow Rays** — Hard shadows via occlusion testing toward the light source
- **Multiple Materials** — Diffuse, specular/mirror, gold, and refractive (glass/water)
- **Procedural Patterns** — Checkerboard texture on planes
- **Animated Scenes** — Objects moving with sine/cosine functions over time
- **Skybox** — Environment mapping for rays that miss all geometry

---

## 📁 Project Structure

```
ex4/Assets/
├── Shaders/
│   ├── RayTracer.compute   # Main compute shader kernel (ray generation, tracing, shading)
│   ├── Ray.cginc           # Ray, RayHit, Material struct definitions
│   ├── Primitives.cginc    # Ray-primitive intersection functions
│   ├── Shading.cginc       # Blinn-Phong, reflection, refraction utilities
│   └── Scenes.cginc        # Scene definitions (6 predefined scenes)
├── Scripts/
│   └── RayTracer.cs        # C# dispatcher: passes camera matrices & parameters to GPU
└── Textures/
    └── Skybox textures
```

---

## 🧮 Algorithms Implemented

### Ray-Sphere Intersection
Solves the quadratic equation from substituting the ray equation into the sphere equation:
```
|O + tD - C|² = r²
→ at² + bt + c = 0
→ t = (-b ± √(b²-4ac)) / 2a
```

### Ray-Plane Intersection
```
t = dot(C - O, N) / dot(D, N)
```
Where `C` is a point on the plane and `N` is the plane normal.

### Ray-Triangle Intersection
Tests if the hit point lies inside the triangle using cross-product edge tests:
```
For each edge (v_i, v_{i+1}):
    cross(edge, point - v_i) must point in same direction as triangle normal
```

### Reflection
```
R = D - 2(D·N)N
```

### Refraction (Snell's Law)
```
η = n1/n2
cos_θi = -dot(N, D)
cos_θt² = 1 - η²(1 - cos_θi²)

If cos_θt² < 0 → total internal reflection
Otherwise: T = η×D + (η×cos_θi - cos_θt)×N
```

### Shadow Testing
For each hit point, cast a ray toward the light. If it intersects any geometry before reaching the light, the point is in shadow.

---

## 🎬 Predefined Scenes

| Scene | Contents |
|-------|----------|
| 0 | Basic spheres and plane |
| 1 | Reflective spheres |
| 2 | Refractive materials (glass/water) |
| 3 | Complex geometry (cylinders, triangles) |
| 4 | Animated spheres |
| 5 | Combined showcase |

---

## ⚙️ Parameters

| Parameter | Description |
|-----------|-------------|
| **Bounce Limit** | Max number of reflection/refraction bounces per ray |
| **Scene Index** | Select which predefined scene to render |
| **Directional Light** | Light direction for shading and shadows |

---

## 🔧 How to Run

1. Open this folder as a Unity project
2. Load the main scene
3. Press Play — the ray tracer renders in real time
4. Adjust bounce limit and scene index in the Inspector to explore different configurations
