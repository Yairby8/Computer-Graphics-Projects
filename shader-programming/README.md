# 🌊 Shader Programming

A suite of GPU shaders implementing procedural noise generation, tangent-space bump mapping, Blinn-Phong illumination, animated water with vertex displacement, and environment-mapped reflections — all running entirely on the GPU.

---

## 🎯 Overview

This project explores real-time GPU rendering through a series of progressively complex vertex and fragment shaders written in HLSL/Cg. It covers the full pipeline from basic noise functions to a fully animated ocean surface with multi-octave Perlin noise displacement, procedural normals, and Fresnel-weighted cube-map reflections.

---

## ✨ Key Features

- **Perlin Noise** — Full 2D and 3D implementation with quintic (smootherstep) interpolation
- **Blinn-Phong Lighting** — Ambient + diffuse + specular shading model
- **Bump Mapping** — Tangent-space normal perturbation from height maps
- **Animated Water** — Vertex displacement + procedural normals using multi-octave 3D Perlin noise
- **Environment Reflections** — Cube-map sampling with Fresnel-based blending
- **Procedural Earth** — Spherical UV mapping, terrain bump maps, atmosphere rim, cloud layer

---

## 📁 Project Structure

```
ex3/Assets/
├── Shaders/
│   ├── Noise.shader       # Value noise & Perlin noise visualization
│   ├── Bricks.shader      # Textured bricks with bump mapping & Blinn-Phong
│   ├── Earth.shader       # Procedural Earth with atmosphere & clouds
│   ├── Water.shader       # Animated water with displacement & reflections
│   ├── Bonus.shader       # Bonus shader effect
│   ├── CGRandom.cginc     # Pseudo-random & Perlin noise functions
│   └── CGUtils.cginc      # Shared utilities (UV mapping, lighting, bump)
└── Textures/              # Height maps, diffuse maps, cube maps
```

---

## 🧮 Techniques Implemented

### Perlin Noise (2D & 3D)
Gradient noise with:
- Pseudo-random gradient vectors at lattice points
- Quintic interpolation (`6t⁵ - 15t⁴ + 10t³`) for C² continuity
- Multi-octave layering for fractal detail

### Blinn-Phong Illumination
```
color = ambient + kd × (N·L) × diffuse + ks × (N·H)^n × specular
```
Where `H = normalize(L + V)` is the half-vector between light and view directions.

### Bump Mapping from Height Maps
Perturbs surface normals in tangent space using finite differences on a height function:
```
du = (h(u + δ, v) - h(u, v)) / δ
dv = (h(u, v + δ) - h(u, v)) / δ
perturbed_normal = normalize(normal - bumpScale × (du × tangent + dv × bitangent))
```

### Animated Water Surface
1. **Vertex displacement** — Offsets vertex Y position using 3D Perlin noise `noise(x, z, time)`
2. **Procedural normals** — Computes bump-mapped normals from noise derivatives
3. **Fresnel reflections** — Blends between surface color and cube-map reflection based on view angle

---

## 🌍 Shader Gallery

| Shader | Description |
|--------|-------------|
| **Noise** | Visualizes raw value noise and Perlin noise patterns |
| **Bricks** | Textured brick wall with height-map bump mapping and specular highlights |
| **Earth** | Planet Earth with diffuse texture, terrain bumps, atmosphere glow, and animated clouds |
| **Water** | Animated ocean surface with vertex displacement, wave normals, and environment reflections |

---

## 🔧 How to Run

1. Open this folder as a Unity project
2. Load the main scene
3. Each material in the scene uses one of the custom shaders — observe them in Play mode
4. Adjust shader parameters (noise scale, time scale, bump intensity) via the Material Inspector
