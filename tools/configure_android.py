"""Configure Godot's Android exporter without editing project paths for each machine."""
import os
import shutil
from pathlib import Path

root = Path(__file__).resolve().parents[1]
sdk = Path(os.environ.get("ANDROID_HOME", os.environ.get("ANDROID_SDK_ROOT", "")))
java = Path(os.environ.get("JAVA_HOME_17_X64", os.environ.get("JAVA_HOME", "/usr/lib/jvm/java-17-openjdk-amd64")))
config = Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config"))) / "godot"
config.mkdir(parents=True, exist_ok=True)
settings = config / "editor_settings-4.5.tres"
settings.write_text('\n'.join([
    '[gd_resource type="EditorSettings" format=3]', '', '[resource]',
    f'export/android/android_sdk_path = "{sdk}"',
    f'export/android/java_sdk_path = "{java}"',
    f'export/android/debug_keystore = "{root / "tools/preview-signing/debug.keystore"}"',
    'export/android/debug_keystore_user = "androiddebugkey"',
    'export/android/debug_keystore_pass = "android"', '',
]))
print("Configured Godot for the Android SDK and the public preview signing identity.")
