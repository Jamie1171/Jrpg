"""Install the pinned Linux engine and Android templates on a disposable CI runner."""
import hashlib
import os
import shutil
import tempfile
import urllib.request
import zipfile
from pathlib import Path

VERSION = "4.5.1"
BASE = f"https://github.com/godotengine/godot/releases/download/{VERSION}-stable/"
FILES = {
    f"Godot_v{VERSION}-stable_linux.x86_64.zip": "02ec53d1cc7dbb9cc6355393c61b9ab43d1244751a124f10248a4802830788cd",
    f"Godot_v{VERSION}-stable_export_templates.tpz": "1998af37f1387684e2c211cdb483daf492fc64dc6b12096bddcdca25b6910c86",
}
binary_dir = Path.home() / ".local/bin"
template_dir = Path.home() / f".local/share/godot/export_templates/{VERSION}.stable"
binary_dir.mkdir(parents=True, exist_ok=True)
template_dir.mkdir(parents=True, exist_ok=True)
with tempfile.TemporaryDirectory(prefix="jrpg-godot-") as scratch:
    for name, expected in FILES.items():
        archive = Path(scratch) / name
        print(f"Downloading {name}", flush=True)
        urllib.request.urlretrieve(BASE + name, archive)
        checksum = hashlib.sha256()
        with archive.open("rb") as stream:
            for chunk in iter(lambda: stream.read(1024 * 1024), b""):
                checksum.update(chunk)
        digest = checksum.hexdigest()
        if digest != expected:
            raise RuntimeError(f"Checksum mismatch: {name}")
        with zipfile.ZipFile(archive) as source:
            if name.endswith(".zip"):
                engine = f"Godot_v{VERSION}-stable_linux.x86_64"
                with source.open(engine) as inp, (binary_dir / "godot").open("wb") as out:
                    shutil.copyfileobj(inp, out)
                (binary_dir / "godot").chmod(0o755)
            else:
                for template in ["android_debug.apk", "android_release.apk"]:
                    with source.open("templates/" + template) as inp, (template_dir / template).open("wb") as out:
                        shutil.copyfileobj(inp, out)
if os.environ.get("GITHUB_PATH"):
    with open(os.environ["GITHUB_PATH"], "a") as path_file:
        path_file.write(str(binary_dir) + "\n")
print(f"Godot {VERSION} installed in {binary_dir}")
