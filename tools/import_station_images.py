#!/usr/bin/env python3
"""チェックポイントのイラストを Assets.xcassets に取り込む。

使い方:
    python3 tools/import_station_images.py tokaido 53/00-new
    python3 tools/import_station_images.py ohenro 88/00-new [--dry-run]

フォルダ内の「NN_なんでも.png」（NN は 01 から始まる番号）を、
「<コースID>_station_<NN-1>」の画像として、横1320px の JPEG に変換して登録する。
"""
import json
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
ASSETS = ROOT / "OsanpoChallenge" / "Assets.xcassets"


def main() -> None:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    dry_run = "--dry-run" in sys.argv
    if len(args) != 2:
        sys.exit(__doc__)
    course_id, folder = args
    source = (ROOT / folder) if not pathlib.Path(folder).is_absolute() else pathlib.Path(folder)

    imported = []
    for path in sorted(source.glob("*.png")):
        match = re.match(r"(\d+)(?:_|\.)", path.name)
        if not match:
            print(f"skip（番号がない）: {path.name}")
            continue
        name = f"{course_id}_station_{int(match.group(1)) - 1:02d}"
        imported.append((path.name, name))
        if dry_run:
            continue
        imageset = ASSETS / f"{name}.imageset"
        imageset.mkdir(exist_ok=True)
        subprocess.run(["sips", "-s", "format", "jpeg", "-s", "formatOptions", "82", "-Z", "1320",
                        str(path), "--out", str(imageset / f"{name}.jpg")],
                       check=True, capture_output=True)
        (imageset / "Contents.json").write_text(json.dumps({
            "images": [{"filename": f"{name}.jpg", "idiom": "universal"}],
            "info": {"author": "xcode", "version": 1},
        }, indent=2) + "\n")

    for src, dst in imported:
        print(f"{src} -> {dst}")
    print(f"{'（確認のみ）' if dry_run else ''}{len(imported)} 枚")


if __name__ == "__main__":
    main()
