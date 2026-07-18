# Contributing watch faces

This repo maintains battery-efficient, always-on-display (AOD) optimised Watch
Face Format (WFF) faces for the Samsung Galaxy Watch 7 (Wear OS 5). Each face is
a resource-only Android module under `faces/`.

## Autopilot build workflow

New watch faces are built in "autopilot" mode by an AI agent, following this
sequence:

1. **Clarify** — before writing anything, ask the requester questions until the
   design is unambiguous: style (analog/digital), layout, colours, complications,
   fonts, what shows in ambient vs interactive, animations, etc.
2. **Finalise the design** — restate the agreed design and get confirmation.
3. **Implement** — add a new module under `faces/<id>/` (see below), keeping it
   code-free (`android:hasCode="false"`, definition in `res/raw/watchface.xml`).
4. **Test** — build (`assembleDebug`/`assembleRelease`), lint, and validate the
   WFF XML (`scripts/wff-validate.sh`).
5. **Benchmark** — run `python3 scripts/benchmark.py` to measure the memory
   footprint (the battery/AOD proxy) and compare against the other faces and the
   Wear OS limits (10 MB ambient / 100 MB interactive).
6. **Document** — add `faces/<id>/README.md` with the design + AOD notes and a
   `face.json` metadata entry so the gallery picks it up.
7. **Open a PR** — include a screenshot/preview of the face in the description
   and the benchmark result. The `pre-commit` hook regenerates the gallery under
   `docs/` and stages it, so the gallery update is part of the same PR. Once
   merged to `main`, the `build-faces` workflow builds APK artifacts, updates
   the gallery download links, and deploys Pages (the `deploy-pages` workflow
   still handles gallery-only doc changes).

## Always-on-display & battery guidelines

The Galaxy Watch 7 uses an OLED display, so battery cost scales with how many
(and how bright) the lit pixels are, especially in the always-on ambient mode.

- **Use a pure-black background** (`#ff000000`); black OLED pixels cost ~nothing.
- **Minimise lit pixels in ambient**: prefer thin fonts, dim colours, and hide
  non-essential elements (seconds, rich graphics) using `Variant mode="AMBIENT"`.
- **Never animate in ambient** and avoid per-second updates in ambient mode.
- **Prefer vector/text over large bitmaps**; bitmap fonts and big images dominate
  the ambient memory budget. Keep the ambient memory footprint low.
- **Validate the memory footprint** with `scripts/benchmark.py`; treat a rising
  `ambientPctOfLimit` as a regression.

## Adding a watch face module

```
faces/<id>/
  build.gradle                       # copy from an existing face; set namespace/applicationId
  face.json                          # gallery metadata (id, name, description, tags, aod, ...)
  README.md                          # design + AOD notes + preview
  src/main/AndroidManifest.xml       # hasCode=false, WFF format version 2
  src/main/res/raw/watchface.xml     # the watch face definition
  src/main/res/xml/watch_face_info.xml
  src/main/res/drawable/preview.png  # required preview image
  src/main/res/values/strings.xml
```

Then register the module in `settings.gradle`:

```groovy
include ':faces:<id>'
```

## Commands

```bash
./gradlew :faces:<id>:assembleDebug     # build one face
./gradlew assembleDebug lintDebug       # build + lint all faces
./scripts/wff-validate.sh 2             # validate WFF XML
python3 scripts/benchmark.py            # memory-footprint benchmark
./scripts/build-artifacts.sh            # build release APKs -> dist/
node scripts/generate-gallery.mjs       # regenerate docs/ gallery
./scripts/setup-hooks.sh                # install the pre-push hook
```
