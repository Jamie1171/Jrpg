# Workflow, decisions and open questions

Recorded 2026-10-06. This is a planning handoff, not a claim that proposed workflows are implemented.

## Established intent

- Mobile, turn-based, stylised 3D JRPG with a freely rotating exploration camera and controller support.
- Semi-open regions made of separately loaded zones, using Final Fantasy XII as a structural reference. Regions can have branches, loops and optional destinations; no seamless continent requirement.
- Existing settlement geometry is a mechanics/art prototype, not a canonical village plan.
- Evaluate suitable existing solutions before substantial custom work; see [reuse-first.md](reuse-first.md).
- Jamie prefers the Meshy ore appearance in the discussed comparison. This does not establish that every category should use Meshy, or that Blender texturing has matched that result.
- Reusable architectural components and shared texture sheets are the desired direction to explore. Natural asset families should vary conspicuous silhouettes; reuse remains appropriate.

## Proposed art-production flow

For architecture: functional top-down layout → architectural concept → simple 3D blockout tested through the actual camera → small reusable kit → detailed materials/assets. Judge movement, sightlines, entry points and useful destinations before polishing a whole settlement. Place settlement features according to function: trade near routes/crossings, homes and workyards with plausible access, clear landmarks and optional exploratory branches.

For Meshy batches: brief → generate initial model through the phone UI → available eligible retries → download and catalogue all outputs → verify durable storage → only then shortlist/process in Blender → integrate selected finished exports. Downloading after each retry may be needed to preserve outputs; Blender processing still waits until the batch is secured.

The proposed split is Meshy geometry plus Blender cleanup/texturing. It remains a hypothesis to compare against Meshy-textured results. Retries provide alternatives and regional variation, not guaranteed snap-compatible modules. Standardise scale, origins and joining surfaces where necessary.

Twelve additional retries mean thirteen outputs including the original. The discussed 300 initial generations/month would therefore imply a conditional ceiling of 3,900 candidates, not finished assets. Neither plan economics nor mode eligibility should be assumed current; recheck exact account/task terms before use. Agent time, processing effort and storage are additional costs.

## Storage and retrieval — not yet selected

A separate asset repository with Git LFS is under consideration; no new repository or paid storage choice has been made. Keep prompts, tags, manifests, licence records and small previews searchable. Preserve raw originals and link them to Blender sources and finished exports. Use stable IDs, batch IDs, seeds/retry numbers, checksums, sizes and selection status. Text search finds metadata, not shapes inside a GLB; contact sheets support visual retrieval.

Verify one authenticated upload/download round trip, compare checksums, and establish selective retrieval and storage/bandwidth costs before scaling. LFS pointers alone are not usable assets. Keep large candidate archives separate from the playable game's selected runtime assets.

## Scope-reduction ideas — proposals, not release commitments

- Monster families can share a base body, rig and animations where compatible, with regional material and shape variations. Geometry generation alone does not establish animation readiness.
- Random encounters could reduce overworld enemy locomotion/navigation work for an initial version. Battle presentation and animations are still needed. Visible roaming enemies later would also affect avoidance, encounter frequency and progression balance.
- Prioritise shared materials, appropriate geometry/detail levels, simple decorative-building shells and separately loaded interiors. Distant impostors and more elaborate streaming are optional techniques to evaluate, not blanket requirements. A rotating camera requires all exposed sides to hold up.
- Zoning does not excuse an overloaded scene. Measure memory, loading, frame time and visual transitions on the intended device.
- Level 60–70 at story completion was a planning target for discussion, not a mandate to inflate campaign length or an approved content count.

## Verification status and unresolved choices

Android remote control was reported tested successfully by Jamie, but the full Meshy prompt/retry/download/archive pipeline remains unproven here. Prior environment access does not guarantee a future chat has the same tools or authentication. Authenticated LFS transfer is unverified. EZ Tree is a candidate, not installed or integrated.

Still open: final art style; kit dimensions and material/texture budgets; best geometry/texturing split; exact retry terms and useful yield; storage and retention; encounter presentation; zone density/load targets; finished game scope; when to resume implementation. Resolve these through bounded experiments when requested, not background production while paused.
