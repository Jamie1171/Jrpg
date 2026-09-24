# Brackenford: the 3D direction

## What changed in 0.2.0

Jamie's target is a freely rotatable, stylised 3D JRPG, closer to Dragon Quest VIII
in presentation. The previous painted-background/tap-to-walk implementation did
not meet that requirement. This build replaces that exploration renderer with
real perspective geometry, character skeletons and direct movement. The existing
story, turn-based combat rules and optional fishing progression carry forward.

This is the first **3D implementation and art pass**, not a claim to match the
finished asset quality, animation or scope of a commercial Dragon Quest game.
The working title remains The Unfinished Dawn. Earlier story options, including
The Hearthroad, remain available.

## Playable now

- Three modelled locations: the inn, village/river landing and woodland clearing.
- A camera-relative left movement stick; independent right-side swipe orbit;
  gentle recentering after forward movement; pitch limits and a spring arm that
  shortens against buildings and tree canopies.
- Seven original rigged character models, with idle, walk and attack clips;
  Rowan and Cael explore together once recruited.
- Physical walls, counters, terrain boundaries and river banks. Interaction is a
  nearby action button rather than clicking a distant destination.
- A genuine 3D battle tableau using the same heroes and original boar models.
- Dialogue portraits rendered from the actual character meshes.
- The same opening quest, battle, fishing, charm, trading, journal and local saves.

## Zero additional spend pipeline

`tools/build_3d_assets.py` runs inside Blender 4.3.2 and creates both editable
`art/blender/*.blend` sources and `game/assets/models/*.glb` runtime assets.
These original meshes were authored procedurally in Blender. No Meshy subscription,
Hugging Face compute, paid API, purchased asset pack or local phone editor is
required. The checked-in GLBs let GitHub Actions build without installing Blender.

The palette is stored in vertex colours; the first pass is **not** hand-painted
texturing or baked ambient occlusion. Godot applies a simple three-band diffuse
shader. Static scenery is combined into spatial chunks sharing that material;
characters each use one mesh surface and an 11-bone skeleton. The JSON mesh
statistics record actual triangles, not a universal performance guarantee.

Godot 4.5.1 uses Compatibility/OpenGL ES for this preview, 2× MSAA and one shadowed
directional light. There is no expensive screen-space effects stack. Renderer
choice and polygon budgets alone cannot guarantee 60 FPS. A stable 30 FPS is the
initial phone acceptance floor; actual frame rate, thermal behaviour, battery
cost and touch ergonomics remain unmeasured on physical devices.

## Save continuity and verification

Version 0.2.0 keeps the preview package identity and signing key. Install it as an
update to retain local progress. Saves keep their story/inventory fields; legacy
pixel positions are recognised by their magnitude and moved to a safe entrance
in the same location. New positions store world x/z metres. Uninstalling removes
the local save.

The automated checks cover game rules and save recovery, plus a rendered complete
opening. The rendered check exercises simultaneous movement and camera touches,
input cancellation at menus, a real counter collision, opposite camera views,
battle victory and three fishing rewards. These checks do not substitute for a
phone playtest. In particular, long-session performance and Android lifecycle
behaviour need physical testing.

## Still needed for the intended presentation

More sculpted faces and hair, stronger costume silhouettes, blended joint weights,
better locomotion/weapon animations, richer terrain and foliage, staged cutscene
shots and authored lighting. The current battle has a basic attack gesture rather
than finished contact choreography or effects. These are asset/animation work on
the new 3D foundation; further painted backdrops are not the exploration direction.
The full campaign, mining, crafting, smithing, additional classes and equipment
progression remain future work, with the cohesive story driving scope.
