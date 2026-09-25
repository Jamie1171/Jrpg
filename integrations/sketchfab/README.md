# Sketchfab access

Store SKETCHFAB_API_TOKEN in repository Actions secrets. Never place credentials in files or model assets.

The Sketchfab asset search and download workflow authenticates on the GitHub runner. Pushes affecting this integration run a search-only smoke check. Under Actions > Sketchfab asset search and download > Run workflow, enter search terms or a 32-character model UID. Downloads default to CC0 and CC BY models only; other licences require review. Successful runs expose a seven-day sketchfab-assets artifact with search metadata or the downloaded model plus attribution.json. This does not publish assets into the game or change an Android build.

Download archives can be imported using Blender's glTF importer after extraction; check scale, materials, geometry and attribution before game integration. A repository secret is not accessible to the separate interactive Blender environment. The runner fetches files on its behalf; account credentials stay in GitHub.

Only read operations against Sketchfab are used. Account profile responses and signed download URLs are neither logged nor included in artifacts. A 200 MB download cap avoids unexpectedly huge assets. Public repository artifacts should contain only assets suitable for redistribution with their attribution.
