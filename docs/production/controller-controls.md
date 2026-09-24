# Controller preview — 0.2.1

Connect the Xbox controller to Android before playing, or connect it while the
app is running. The game uses Godot's normalised Xbox button/axis layout. No
remapping screen, paid service or new Android permission is needed.

| Control | Exploring | Menus / dialogue / battle |
| --- | --- | --- |
| Left stick | Analogue movement | Navigate choices |
| Right stick | Orbit camera | Scroll journal |
| D-pad | — | Navigate choices; hold to repeat |
| A | Interact with the nearest person/marker | Activate the highlighted button |
| B | — | Back; deliberately does not skip dialogue or flee an active battle |
| X | Satchel | — |
| Y | Journal | — |
| Menu | Pause menu | Back where available |

A gold border highlights the selected button. Dialogue starts on Continue;
Skip scene is a separate selectable button. Battles start on Strike; navigate
up to enemy target buttons and left/right among commands. Disabled actions are
skipped. After settings change or battle actions, focus is restored where possible.

The movement and camera sticks have a 22% radial deadzone. Camera speed is
frame-rate independent. A held movement stick cannot start navigating a newly
opened menu until it returns to centre. Closing a menu also waits for both sticks
to centre before allowing world movement. Disconnecting clears held controls;
app focus loss blocks controller input. Recentre sticks after returning to the app.

Controller legends replace the touch stick when a controller is used. Touching
the screen brings the touch controls back; both input paths remain available.
The existing save format, preview package and signing key are unchanged.

## Verification

The rendered test injects normalised Godot joypad events and covers title/start,
exactly one dialogue advance per A press, analogue movement and camera, drift,
nearby interaction, D-pad navigation, setting focus after rebuild, journal scroll,
battle Strike/Shield Bash, disconnect recovery and app focus. The existing touch
and complete-story checks still run. These are input-routing tests, not physical
Bluetooth or Xbox firmware tests. Jamie reported that 0.2.0 worked with a solid
frame rate on the test phone; controller pairing and mapping still need the first
physical controller playtest.

Godot references:
- https://docs.godotengine.org/en/4.5/tutorials/inputs/controllers_gamepads_joysticks.html
- https://docs.godotengine.org/en/4.5/tutorials/ui/gui_navigation.html
