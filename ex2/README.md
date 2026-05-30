# 🔺 Mesh Processing & Shading

Loading, processing, and rendering 3D meshes from OBJ files with custom normal calculation and support for both flat and smooth shading modes.

---

## 🎯 Overview

This project implements a complete mesh processing pipeline: parsing Wavefront OBJ files, computing surface normals, and rendering meshes with either flat or smooth (Gouraud) shading. All normal calculations are done manually using cross products and vertex-normal averaging.

---

## ✨ Key Features

- **OBJ Parser** — Reads Wavefront `.obj` files (vertices and triangle faces) into a custom mesh structure
- **Smooth Shading** — Per-vertex normals computed by averaging the normals of all adjacent faces
- **Flat Shading** — Vertex duplication so each triangle gets its own unique normal, producing hard edges
- **Normal Calculation** — Cross-product based face normals, accumulated per vertex and normalized
- **Unity Integration** — Converts processed mesh data into Unity's `Mesh` class for rendering

---

## 📁 Project Structure

```
ex2/Assets/
├── Scripts/
│   ├── MeshData.cs       # Core mesh structure: vertices, triangles, normals
│   ├── MeshViewer.cs     # Unity component that loads and displays meshes
│   └── OBJParser.cs      # Wavefront OBJ file parser
└── Models/               # Sample 3D models in OBJ format
```

---

## 🧮 Algorithms Implemented

### Per-Vertex Normal Calculation (Smooth Shading)
For each triangle, compute the face normal via cross product of two edges. Accumulate this normal to each of the triangle's three vertices. After processing all faces, normalize each vertex normal:

```
face_normal = normalize(cross(v1 - v0, v2 - v0))
vertex_normal[i] += face_normal   (for each vertex i in the face)
vertex_normal[i] = normalize(vertex_normal[i])
```

This produces smooth shading by interpolating normals across the surface.

### Flat Shading via Vertex Duplication
To achieve flat shading, each triangle is given its own copy of its vertices. This ensures no normal sharing between adjacent faces:

```
For each triangle (v0, v1, v2):
    Create v0', v1', v2' as new unique vertices
    Assign face_normal to all three
```

The result is distinct, faceted surfaces with hard edges between polygons.

---

## 🎨 Shading Comparison

| Mode | Appearance | Technique |
|------|-----------|-----------|
| **Smooth** | Curved, continuous surface | Shared vertex normals (averaged) |
| **Flat** | Faceted, polygonal look | Duplicated vertices, per-face normals |

---

## 🔧 How to Run

1. Open this folder as a Unity project
2. Load the main scene
3. Use the Inspector to select an OBJ model and toggle between flat/smooth shading
