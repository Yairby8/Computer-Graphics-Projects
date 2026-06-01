# 🦴 Skeletal Animation

Real-time character animation driven by BVH (Biovision Hierarchy) motion capture data, with a custom forward kinematics pipeline, hand-rolled matrix transforms, and quaternion SLERP interpolation.

---

## 🎯 Overview

This project implements a complete skeletal animation system that parses BVH motion capture files and renders an animated character in real time. The entire transformation pipeline — rotation matrices, quaternion operations, and frame interpolation — is built from scratch without relying on Unity's built-in `Quaternion` class for the core math.

---

## ✨ Key Features

- **BVH Parser** — Reads hierarchical joint definitions and per-frame channel data from standard BVH files
- **Forward Kinematics** — Recursively applies parent-to-child transforms down the skeleton tree
- **Custom Matrix Math** — 4×4 homogeneous transformation matrices for translation, rotation, and scale
- **Quaternion SLERP** — Smooth interpolation between keyframes using spherical linear interpolation
- **Euler → Quaternion** — Supports arbitrary rotation orders (XYZ, ZYX, etc.) as defined in BVH files
- **Visual Skeleton** — Spheres at joints, cylinders as bones aligned via `RotateTowardsVector()`

---

## 📁 Project Structure

```
ex1/Assets/
├── BVHParser.cs          # Parses BVH files into joint hierarchy + keyframe data
├── CharacterAnimator.cs  # Main controller: builds skeleton, applies FK, interpolates
├── MatrixUtils.cs        # Custom 4x4 matrix operations (translate, rotate, scale)
├── QuaternionUtils.cs    # Quaternion multiply, conjugate, SLERP, Euler conversion
└── BVH/                  # Sample motion capture files
    ├── Dance.bvh.txt
    ├── Walking.bvh.txt
    ├── Yoga.bvh.txt
    ├── Cheer.bvh.txt
    ├── Balance.bvh.txt
    └── ...
```

---

## 🧮 Algorithms Implemented

### Forward Kinematics
Each joint's world transform is computed by concatenating local rotations down the hierarchy:

```
T_world = T_parent × T_local_translation × R_z × R_y × R_x
```

### Quaternion SLERP
Smooth rotation interpolation between keyframes:

```
SLERP(q1, q2, t) = q1 × sin((1-t)θ)/sin(θ) + q2 × sin(tθ)/sin(θ)
```

Where θ is the angle between the two quaternions. Handles the shortest-path case by negating when the dot product is negative.

### Euler to Quaternion
Converts Euler angles with arbitrary axis ordering to a unit quaternion via axis-angle composition.

---

## 🎬 Included Animations

| File | Motion |
|------|--------|
| `Walking.bvh.txt` | Walking cycle |
| `Dance.bvh.txt` | Dance routine |
| `Yoga.bvh.txt` | Yoga poses |
| `Cheer.bvh.txt` | Cheerleading |
| `Balance.bvh.txt` | Balancing act |
| `Bridge.bvh.txt` | Bridge pose |
| `Marcher.bvh.txt` | Marching |
| `Drink.bvh.txt` | Drinking motion |

---

## 🕹️ Controls

- **Animate** toggle — Start/stop playback
- **Interpolate** toggle — Enable SLERP between keyframes (vs. snapping)
- **Animation Speed** slider — Control playback rate

---

## 🔧 How to Run

1. Open this folder as a Unity project
2. Load `MainScene.unity`
3. Press Play and use the Inspector to toggle animation and interpolation
