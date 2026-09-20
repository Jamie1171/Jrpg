# From story treatment to a playable Android JRPG

**Status:** Proposed production roadmap, 20 September 2026. No engine project or build pipeline has been implemented yet.

The working example is [The Unfinished Dawn](../story/the-unfinished-dawn-treatment.md). The earlier concepts, including The Hearthroad, remain available. This roadmap allows us to test the new direction before committing to the entire campaign.

## The first outcome

A short Android build in which the player can explore part of Brackenford, meet Rowan's family, travel with Cael, complete a delivery, fight a small encounter, try an optional fishing activity, save and return.

Aim for roughly 10–15 minutes as a test of the game's feel, not a promise of delivery time or the final opening's length. The first build does not need to contain Mira's death. Establishing why the player should care about these people comes first.

The next, larger slice extends that foundation through the attack and escape, once the ordinary-life scenes, controls and battle system work.

## 1. Turn the treatment into playable scenes

Write a compact opening chapter specification, keeping the complete ending and betrayal in view.

For every scene, record:

- Where Rowan is and what he currently wants.
- Who is present and what each person wants.
- The player's actions, rather than only dialogue or exposition.
- The information introduced and what it prepares for later.
- The quest and character state before and after the scene.
- Its required locations, characters, props, sounds and animations.

Suggested first sequence:

| Scene | Player activity | Purpose |
|---|---|---|
| Morning at the inn | Speak to Mira and Tessa; collect a delivery. | Establish Rowan's wish to leave and the responsibilities he takes for granted. |
| Brackenford crossing | Navigate the landing and resolve a small delivery problem. | Teach interaction while making the settlement specific. |
| The hillside path | Travel with Cael and fight one small encounter. | Establish friendship through conversation and cooperation. |
| Festival preparations | Return to a changed scene; optionally visit the fishing stall. | Provide a quiet reward and show activities outside the main objective. |
| Ysra's arrival | Observe Mira's reaction and a short conversation. | End the sample with a story question that leads into the larger chapter. |

Keep trade participation optional throughout. The delivery must not require crafted equipment or a fishing achievement.

**Ready to build when:** each scene has a purpose, playable actions and a clear completion state. We do not need a fully written ten-chapter screenplay before testing the opening.

## 2. Prove a manageable visual style

Proposed starting direction: a fixed three-quarter view with layered 2D environments, shaded character sprites, foreground occlusion, shadows and limited animated details. This can suggest depth while keeping the first area's camera and asset requirements controlled.

Create a small reference set:

- Rowan, Mira and Cael: consistent proportions, silhouettes, clothing and palette.
- One Brackenford street/river view and the inn interior.
- A dialogue panel and a battle layout readable on a phone.
- One actual walking character at gameplay size.

Generate concept images and portraits as references, then prepare usable game assets. Walking frames need aligned feet, consistent scale, clean transparency and matching equipment. Scenery needs collision and walkable areas that agree with the image. These are production tasks, not automatic properties of generated artwork.

Test one attractive corner of the village early, while allowing temporary assets elsewhere. Avoid making hundreds of images before proving how they work in motion.

Blender may later help create repeatable models, camera angles and sprite renders. It is not a prerequisite for the first 2D prototype. If the sprite workflow proves too inconsistent, compare it with simple reusable 3D models before expanding the cast.

**Ready to expand when:** a moving character looks consistent in a representative scene and important objects remain legible on the actual phone.

## 3. Establish the remote Android build

Proposed foundation: Godot with GDScript, GitHub version control and a standard Linux GitHub Actions runner.

Godot's Android export process requires engine/export components plus Java and Android SDK configuration. These would be installed in the build environment rather than on the player's phone. See [Godot's Android export documentation](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html).

GitHub documents free standard hosted runner use for public repositories. Avoid paid larger runners; configure limited build retention and check the account's artifact/storage allowances before accumulating builds. Free compute does not justify an unlimited-storage assumption. See [GitHub Actions billing](https://docs.github.com/en/billing/concepts/product-billing/github-actions).

The first technical proof should be a minimal installable APK:

1. Pin a compatible Godot version and matching export templates.
2. Create a small project with a touch-controlled scene.
3. Configure Android export and a repeatable test-signing approach.
4. Check repository workflow permissions and run a real build.
5. Download, install and launch it on the target phone.
6. Repeat the build and verify that an update installs and preserves a test save.

Do not describe the pipeline as working until a real build succeeds. Workflow permissions or account settings may require an owner action; establish that early. Keep signing secrets out of the public repository. No paid inference service is required for this technical proof.

**Ready to build gameplay when:** the build is reproducible and a phone can install, launch and update it.

## 4. Build the shared game foundations

| System | First version | Important behaviour |
|---|---|---|
| Exploration | Touch movement, collision, camera and interaction prompts. | Rowan can reach intended destinations without precise finger placement. |
| Dialogue and scenes | Portraits, text, actor movement, pause, skip and dialogue history. | Skipping applies the same story changes as watching. |
| Quests | A small set of explicit scene and objective states. | Re-entering a map does not duplicate a reward or restart a finished scene. |
| Party and combat | Rowan and Cael, fully paused turns, attack, guard, skills, items and clear targets. | Cooperation is useful; ordinary encounters are not prolonged tapping exercises. |
| Inventory | A small item set, equipment and readable effects. | Players can understand what changes before equipping something. |
| Saving | Versioned save data, checkpoint recovery and a backup strategy. | Leaving or backgrounding the app does not silently discard completed progress. |
| Optional activity | One short fishing interaction with a useful reward. | It teaches the activity's choices and can be skipped without blocking the chapter. |
| Settings | Text size, audio controls and reduced motion where needed. | Essential information is visible and is never carried only by sound or colour. |

Keep dialogue, items, enemies and quests in structured data so later chapters can use the same systems.

## 5. Bring the scenes to life

Use in-engine staging for the first cutscenes: characters move, turn, pause, change expressions and respond to one another while camera and sound support the scene. Reuse the same locations and character assets that appear in play.

A few illustrated panels may support special moments. Full voice acting and generated video are optional later production choices, not dependencies for telling the opening well. Record asset provenance and licences as assets enter the project.

Treat music and sound as part of pacing, while keeping every important cue understandable through text or visuals.

## 6. Test the experience before expanding it

Automated checks can cover scene loading, story-state transitions, combat calculations, saves and Android export. Human play is needed to judge timing, readability, touch comfort, character chemistry and whether the activity is enjoyable.

The first feedback questions are concrete:

- Can the player explain what Rowan wants and how Mira feels about it?
- Does Cael feel like a friend before the later story asks the player to care about his betrayal?
- Is movement comfortable without a controller?
- Does the first fight require an understandable choice?
- Is fishing enjoyable enough to try again without being necessary?
- Can the player stop, resume and remember the current objective?

After this works, extend the build through the attack and escape. Then add Ysra's recruitment and the next region. Introduce later trades one at a time, with distinctive rewards and optional adventures.

## Working together from a phone

The assistant's work includes story scripts, data, code, asset preparation, scene assembly and build automation where connected access permits. The user supplies creative feedback and installs builds to judge how they feel on the target device. There is no need for the proposed workflow to involve manually operating a desktop editor from a phone.

Visual generation and automated modelling still require consistency checks and iteration. Available service limits and access must be verified when used; an untested Hugging Face or Blender integration is not a production dependency.

Use small reviewable checkpoints: a character in motion, a scene in the village, a battle, a playable opening. This allows feedback such as “Mira feels too stern” or “the controls cover the scenery” while changes are still inexpensive.

## Immediate work order

1. Write the opening's scene specification and a small asset list.
2. Prove the minimal Godot-to-Android build route.
3. Produce and test one coherent visual sample.
4. Implement the shared foundations needed by the opening.
5. Assemble the Brackenford sample and get phone feedback.
6. Extend through the first dramatic event; revise before building later chapters.

The target is zero additional development spending using available access and free tools, with a deliberately small initial scope. This is a route to testing the game, not a claim that a full commercial JRPG can be produced instantly or without sustained iteration.
