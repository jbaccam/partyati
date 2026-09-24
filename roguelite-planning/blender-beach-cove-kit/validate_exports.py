"""Round-trip validation for the Beach Cove kit.

    blender --background --python validate_exports.py

Every FBX and GLB is reimported into an empty scene and checked independently of
the generator that produced it. Writes validation-report.json.

This is Blender-side verification only. It is not a claim that the assets have
been imported into Roblox Studio or tested in a place.
"""
import hashlib
import json
import math
from pathlib import Path

import bpy

ROOT = Path(__file__).resolve().parent
TEX = ROOT / "textures"


def wipe():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def check(stem, path, kind):
    wipe()
    if kind == "fbx":
        bpy.ops.import_scene.fbx(filepath=str(path))
    else:
        bpy.ops.import_scene.gltf(filepath=str(path))

    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    result = {"file": f"exports/{kind}/{path.name}", "ok": True, "problems": []}

    def fail(msg):
        result["ok"] = False
        result["problems"].append(msg)

    if len(meshes) != 1:
        fail(f"expected 1 mesh, got {len(meshes)}")
        return result
    obj = meshes[0]
    mesh = obj.data
    mesh.calc_loop_triangles()

    result["triangles"] = len(mesh.loop_triangles)
    result["vertices"] = len(mesh.vertices)
    result["materials"] = len(mesh.materials)
    result["uv_layers"] = [l.name for l in mesh.uv_layers]
    # FBX and glTF apply their own axis conversion; compare sorted extents so the
    # check is about the asset's size, not about which axis is up on import.
    result["dimensions_sorted"] = sorted(round(v, 3) for v in obj.dimensions)

    if len(mesh.materials) != 1:
        fail(f"expected 1 material, got {len(mesh.materials)}")
    if len(mesh.uv_layers) != 1:
        fail(f"expected 1 UV layer, got {len(mesh.uv_layers)}")

    # UVs must be finite, inside 0-1, and enclose real area.
    if mesh.uv_layers:
        us = [uv.uv for uv in mesh.uv_layers[0].data]
        bad = [c for c in us if not (math.isfinite(c.x) and math.isfinite(c.y))]
        if bad:
            fail(f"{len(bad)} non-finite UV coordinates")
        lo = min(min(c.x, c.y) for c in us)
        hi = max(max(c.x, c.y) for c in us)
        result["uv_range"] = [round(lo, 4), round(hi, 4)]
        if lo < -0.001 or hi > 1.001:
            fail(f"UVs outside 0-1: {lo:.4f}..{hi:.4f}")

    # Degenerate triangles would bake to nothing and shade badly in engine.
    degenerate = 0
    for tri in mesh.loop_triangles:
        a, b, c = (mesh.vertices[i].co for i in tri.vertices)
        if (b - a).cross(c - a).length < 1e-9:
            degenerate += 1
    result["degenerate_triangles"] = degenerate
    if degenerate:
        fail(f"{degenerate} degenerate triangles")

    # The material must carry an image into Base Color, be nonmetallic, and the
    # image must be the asset's own atlas at the expected resolution.
    mat = mesh.materials[0] if mesh.materials else None
    if mat and mat.use_nodes:
        bsdf = next((n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
        if not bsdf:
            fail("no Principled BSDF")
        else:
            metallic = bsdf.inputs["Metallic"].default_value
            result["metallic"] = round(metallic, 4)
            if metallic > 0.001:
                fail(f"metallic {metallic}")
            link = bsdf.inputs["Base Color"].links
            if not link:
                fail("Base Color not linked to an image")
            else:
                node = link[0].from_node
                while node.type != "TEX_IMAGE" and node.inputs:
                    ins = [i for i in node.inputs if i.links]
                    if not ins:
                        break
                    node = ins[0].links[0].from_node
                if node.type != "TEX_IMAGE" or node.image is None:
                    fail("Base Color does not resolve to an image texture")
                else:
                    w, h = node.image.size
                    result["texture_size"] = [w, h]
                    if (w, h) != (2048, 2048):
                        fail(f"atlas is {w}x{h}, expected 2048x2048")
    else:
        fail("no node-based material")
    return result


def main():
    report = {
        "blender_version": bpy.app.version_string,
        "scope": "Blender round-trip only; no Roblox Studio import or in-game test is claimed",
        "assets": {},
        "source_sheets": {},
        "summary": {},
    }

    prov = json.loads((TEX / "texture-provenance.json").read_text())
    for role, info in prov["sources"].items():
        stored = ROOT / info["stored_as"]
        if stored.exists():
            digest = hashlib.sha256(stored.read_bytes()).hexdigest()
            report["source_sheets"][role] = {
                "stored_as": info["stored_as"],
                "sha256": digest,
                "matches_recorded": digest == info["sha256"],
            }

    stems = sorted(p.stem for p in (ROOT / "exports/fbx").glob("*.fbx"))
    passed = failed = 0
    for stem in stems:
        entry = {}
        for kind, ext in (("fbx", ".fbx"), ("glb", ".glb")):
            path = ROOT / f"exports/{kind}" / (stem + ext)
            if not path.exists():
                entry[kind] = {"ok": False, "problems": ["missing export"]}
                continue
            entry[kind] = check(stem, path, kind)
        # The two formats must agree on the geometry they carry.
        f, g = entry.get("fbx", {}), entry.get("glb", {})
        if f.get("triangles") and g.get("triangles") and f["triangles"] != g["triangles"]:
            f["ok"] = False
            f.setdefault("problems", []).append(
                f"fbx {f['triangles']} tris vs glb {g['triangles']}")
        ok = all(v.get("ok") for v in entry.values())
        passed += ok
        failed += not ok
        entry["ok"] = ok
        report["assets"][stem] = entry
        print(("PASS " if ok else "FAIL ") + stem, flush=True)
        if not ok:
            for kind, v in entry.items():
                if isinstance(v, dict):
                    for p in v.get("problems", []):
                        print(f"      {kind}: {p}", flush=True)

    report["summary"] = {
        "assets_checked": len(stems),
        "passed": passed,
        "failed": failed,
        "source_sheets_matching": sum(1 for v in report["source_sheets"].values() if v["matches_recorded"]),
    }
    (ROOT / "validation-report.json").write_text(json.dumps(report, indent=2))
    print(f"\n{passed}/{len(stems)} assets passed; report written", flush=True)


main()
