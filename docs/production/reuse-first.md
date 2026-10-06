# Reuse before rebuilding

Recorded 2026-10-06 from Jamie's requested project rule.

Before implementing a substantial feature or creating an asset workflow, check for suitable existing open-source tools and reusable assets. Prefer adapting an existing solution when its licence, visual style, platform support and integration effort suit this project. Build from scratch when that produces a clearly better or simpler result.

This applies to generators, Blender add-ons, shaders, water/wind effects, importers, optimisation tools, modular kits and other appropriate systems. Keep investigation bounded to the current need; do not turn a small fix into an exhaustive repository survey.

## Evaluation and adoption

1. Define the actual need and target engine/renderer/device.
2. Inspect plausible existing solutions and their source/documentation. Public availability alone is not reuse permission.
3. Check code and bundled asset licences separately, modification/distribution requirements, dependencies and attribution. Do not assume a generator's code licence settles every output or included texture's terms.
4. Assess art-style adaptability, maintenance, integration effort and mobile performance. A tool used offline need not run inside Godot; an exported asset still needs import verification.
5. Choose reuse, adaptation or custom work and record a short reason. Pin the adopted version/commit and preserve required notices.
6. Validate a representative scene, including combined effects and target-device performance, before broad rollout.

Record candidates and outcomes in [reuse-register.md](reuse-register.md). Add adopted runtime asset provenance to [the existing manifest](../art/asset-manifest.md) and applicable distributed notices. A rejected candidate with a short reason is useful evidence; do not repeatedly research it without new information.

No candidate in the register is automatically approved for installation, integration or spending. Apply the scope of the current user request.
