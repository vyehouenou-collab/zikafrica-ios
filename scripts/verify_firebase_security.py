"""Fail the build if Firebase was not resolved to the reviewed security patch."""
import json
from pathlib import Path

root = Path(__file__).resolve().parent.parent
path = root / "ZikAfrica.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
data = json.loads(path.read_text())
pins = data.get("pins", data.get("object", {}).get("pins", []))
pin = next(p for p in pins if p.get("identity", p.get("package", "")).lower() == "firebase-ios-sdk")
version = pin["state"].get("version")
if version != "12.19.3":
    raise SystemExit(f"Unexpected Firebase SDK: {version}; expected security patch 12.19.3")
print(f"Firebase security patch verified: {version}")
