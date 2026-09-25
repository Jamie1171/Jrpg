# Blender-only ore experiment

Original scripted geometry and procedural materials, baked to one 1024px colour texture. No Meshy generation or image generation used to create this asset. Meshy IronOre.glb is imported only after export/save for comparison renders.

Run Blender 4.3.2:

    blender --background --python art/blender-ore-trial/generate.py

Deliverables: editable BlenderIronOre.blend, portable BlenderIronOre.glb, front/back renders and comparison.jpg. stats.json records the actual export size and triangle count. Both comparison subjects are normalized to 1.25m measured height and use identical cameras/lights. Size figures concern source GLB files, not final APK storage.

Assessment: the Blender experiment proves a fully free procedural modelling/texturing route. It is less polished than the Meshy example: repeated faceted pieces, straighter bevel markings, and a less natural ore distribution. This is a first scripted attempt, not a limit of Blender. It uses substantially fewer triangles, so these are workflow examples rather than equal-geometry-budget quality benchmarks. More art direction and modelling work would be required to match the reference.

The app and existing ore placements are unchanged. No phone performance measurement was made for this experiment.
