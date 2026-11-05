#!/usr/bin/env python3
"""
glb_to_image.py

Convert a .glb (or .gltf) 3D model file into a normal 2D image (PNG/JPG)
that can be viewed like any regular photo — no 3D viewer needed.

Requirements (install once):
    pip install trimesh pyrender pillow numpy --break-system-packages

Usage:
    python3 glb_to_image.py model.glb
    python3 glb_to_image.py model.glb -o render.png
    python3 glb_to_image.py model.glb --width 1600 --height 1600
    python3 glb_to_image.py model.glb --views 4          # render 4 angles
    python3 glb_to_image.py model.glb --bg white          # background color
    python3 glb_to_image.py model.glb --angle 45 --elevation 20

Notes:
    - Runs headless (no display / GPU window needed). It uses EGL for
      hardware-accelerated offscreen rendering when available, and falls
      back to OSMesa (software) automatically if EGL isn't available.
    - Works for both single-mesh and multi-mesh/animated GLBs (renders
      the default pose).
"""

import argparse
import os
import sys

# Must be set BEFORE importing pyrender, so set a sane default here.
# EGL = hardware accelerated headless rendering (preferred).
# If that fails at runtime, we retry the whole process with OSMesa.
os.environ.setdefault("PYOPENGL_PLATFORM", "egl")

import numpy as np  # noqa: E402


def render_glb(
    glb_path: str,
    out_path: str = None,
    width: int = 1200,
    height: int = 1200,
    bg_color=(255, 255, 255, 255),
    yaw_deg: float = 45.0,
    pitch_deg: float = 20.0,
    zoom: float = 1.6,
):
    """Render a single image of the GLB from a given camera angle."""
    import trimesh
    import pyrender

    if not os.path.exists(glb_path):
        raise FileNotFoundError(f"Could not find file: {glb_path}")

    # 1. Load the GLB as a trimesh Scene (handles multiple meshes/materials)
    tm_scene = trimesh.load(glb_path, force="scene")

    # 2. Convert to a pyrender scene we can render offscreen
    scene = pyrender.Scene.from_trimesh_scene(
        tm_scene, bg_color=[c / 255.0 for c in bg_color]
    )

    # 3. Figure out the model's bounding box so we can frame the camera
    bounds = tm_scene.bounds  # shape (2, 3): min/max corners
    center = bounds.mean(axis=0)
    extent = np.linalg.norm(bounds[1] - bounds[0])
    if extent == 0:
        extent = 1.0
    cam_distance = extent * zoom

    # 4. Build a camera pose orbiting around the model at (yaw, pitch)
    yaw = np.radians(yaw_deg)
    pitch = np.radians(pitch_deg)
    cam_pos = center + cam_distance * np.array(
        [
            np.cos(pitch) * np.sin(yaw),
            np.sin(pitch),
            np.cos(pitch) * np.cos(yaw),
        ]
    )

    def look_at(eye, target, up=np.array([0, 1, 0])):
        forward = (target - eye)
        forward = forward / np.linalg.norm(forward)
        right = np.cross(forward, up)
        right = right / np.linalg.norm(right)
        true_up = np.cross(right, forward)
        mat = np.eye(4)
        mat[:3, 0] = right
        mat[:3, 1] = true_up
        mat[:3, 2] = -forward
        mat[:3, 3] = eye
        return mat

    cam_pose = look_at(cam_pos, center)

    camera = pyrender.PerspectiveCamera(yfov=np.pi / 4.0, aspectRatio=width / height)
    scene.add(camera, pose=cam_pose)

    # 5. Lighting — a couple of soft directional lights so the model isn't flat
    light = pyrender.DirectionalLight(color=np.ones(3), intensity=4.0)
    scene.add(light, pose=cam_pose)
    fill_pose = look_at(
        center + cam_distance * np.array([-0.6, 0.8, -0.4]), center
    )
    scene.add(pyrender.DirectionalLight(color=np.ones(3), intensity=2.0), pose=fill_pose)

    # 6. Render offscreen
    renderer = pyrender.OffscreenRenderer(width, height)
    try:
        color, _depth = renderer.render(scene, flags=pyrender.RenderFlags.RGBA)
    finally:
        renderer.delete()

    # 7. Save as a normal image file
    from PIL import Image

    img = Image.fromarray(color)
    if out_path is None:
        base = os.path.splitext(os.path.basename(glb_path))[0]
        out_path = f"{base}_render.png"
    img.save(out_path)
    return out_path


def render_with_fallback(glb_path, **kwargs):
    """Try EGL (hardware) first; fall back to OSMesa (software) if it fails."""
    try:
        return render_glb(glb_path, **kwargs)
    except Exception as e:
        sys.stderr.write(f"[info] EGL render failed ({e}); retrying with OSMesa...\n")
        os.environ["PYOPENGL_PLATFORM"] = "osmesa"
        # Reload pyrender's GL backend by re-importing in a subprocess-free way
        for mod in list(sys.modules):
            if mod.startswith("pyrender") or mod.startswith("OpenGL"):
                del sys.modules[mod]
        return render_glb(glb_path, **kwargs)


def main():
    parser = argparse.ArgumentParser(description="Render a .glb file to a normal 2D image.")
    parser.add_argument("glb_path", help="Path to the input .glb / .gltf file")
    parser.add_argument("-o", "--output", default=None, help="Output image path (.png/.jpg)")
    parser.add_argument("--width", type=int, default=1200)
    parser.add_argument("--height", type=int, default=1200)
    parser.add_argument("--bg", default="white", choices=["white", "black", "transparent"],
                         help="Background color")
    parser.add_argument("--angle", type=float, default=45.0, help="Camera yaw angle in degrees")
    parser.add_argument("--elevation", type=float, default=20.0, help="Camera pitch angle in degrees")
    parser.add_argument("--zoom", type=float, default=1.6, help="Camera distance multiplier")
    parser.add_argument("--views", type=int, default=1,
                         help="Render N evenly-spaced views around the model instead of just one")
    args = parser.parse_args()

    bg_map = {
        "white": (255, 255, 255, 255),
        "black": (0, 0, 0, 255),
        "transparent": (0, 0, 0, 0),
    }
    bg_color = bg_map[args.bg]

    if args.views <= 1:
        out_path = render_with_fallback(
            args.glb_path,
            out_path=args.output,
            width=args.width,
            height=args.height,
            bg_color=bg_color,
            yaw_deg=args.angle,
            pitch_deg=args.elevation,
            zoom=args.zoom,
        )
        print(f"Saved image: {out_path}")
    else:
        base = os.path.splitext(args.output or os.path.basename(args.glb_path))[0]
        for i in range(args.views):
            yaw = (360.0 / args.views) * i
            out_path = f"{base}_view{i+1}.png"
            render_with_fallback(
                args.glb_path,
                out_path=out_path,
                width=args.width,
                height=args.height,
                bg_color=bg_color,
                yaw_deg=yaw,
                pitch_deg=args.elevation,
                zoom=args.zoom,
            )
            print(f"Saved image: {out_path}")


if __name__ == "__main__":
    main()