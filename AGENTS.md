# AGENTS.md

This repository holds **Watch Face Format (WFF)** watch faces for the Samsung
Galaxy Watch 7 (Wear OS 5). Watch faces are **resource-only**: no Java/Kotlin,
`android:hasCode="false"`, and the face is defined in `res/raw/watchface.xml`.
Target WFF **version 2** / **API 34** (Galaxy Watch 7 ships Wear OS 5).

Standard build/lint/validate commands and project layout live in `README.md`.
The autopilot build workflow (clarify → design → implement → test → benchmark →
document → PR) and AOD/battery guidelines live in `CONTRIBUTING.md`. Follow that
workflow when asked to create a new watch face, including asking clarifying
questions before implementing.

## Cursor Cloud specific instructions

- Android SDK is installed at `~/android-sdk` (`platforms;android-34`,
  `build-tools;34.0.0`, `platform-tools`). `ANDROID_HOME` is exported from
  `~/.bashrc` for interactive shells. Because `local.properties` is gitignored,
  the update script regenerates it (`sdk.dir=$HOME/android-sdk`) so Gradle finds
  the SDK in non-interactive shells too.
- Build/lint from the repo root, e.g. `./gradlew :faces:simple-digital:assembleDebug`
  and `./gradlew :faces:simple-digital:lintDebug`. The Gradle wrapper (8.7) and
  AGP 8.5.2 run fine on the preinstalled JDK 21.
- **No KVM in this environment** (`/dev/kvm` is absent), so the Wear OS emulator
  cannot run and faces cannot be rendered/screenshotted here. Verify work by
  (a) building the APK and (b) validating the WFF XML — do NOT expect to launch
  an emulator.
- The official WFF validator jar is kept at `~/wff-tools/wff-validator.jar`.
  Run `./scripts/wff-validate.sh 2` to validate all faces. If the jar is ever
  missing, rebuild it per the instructions in the script header (clone
  `github.com/google/watchface`, then
  `./gradlew :specification:validator:executable-jar` in `third_party/wff`).
- When adding a new face: create a module under `faces/`, add it to
  `settings.gradle`, include a `res/drawable/preview.png` (required by
  `watch_face_info.xml`), keep the module code-free, then build + validate.
- **Battery/AOD benchmark:** `python3 scripts/benchmark.py` builds release APKs
  and runs Google's Memory Footprint Evaluator (jar at
  `~/wff-tools/memory-footprint.jar`), writing `faces/<id>/benchmark.json`. This
  static memory footprint is the device-independent battery/AOD proxy — actual
  battery numbers need a physical Galaxy Watch 7, which cannot run here.
- **Gallery webpage:** `node scripts/generate-gallery.mjs` regenerates the
  static, searchable gallery under `docs/`. The `pre-commit` hook runs this
  automatically whenever a face changes and stages `docs/`, so every PR that
  touches a face also updates the gallery. The only CI is
  `.github/workflows/deploy-pages.yml` (tag push) and
  `.github/workflows/release.yml` (tag push), which deploy `docs/` to GitHub
  Pages and publish APKs when a release tag is pushed (Pages source must be set
  to "GitHub Actions").
- **Git hooks** (activated via `core.hooksPath`, set by the startup update
  script; otherwise run `./scripts/setup-hooks.sh`):
  - `pre-commit`: regenerates + stages `docs/` when a watch face changes.
  - `pre-push`: build + lint + WFF validation.
- The `~/wff-tools/` jars (`wff-validator.jar`, `memory-footprint.jar`) are built
  from `github.com/google/watchface`; rebuild per the headers in
  `scripts/wff-validate.sh` / `scripts/benchmark.py` if the directory is empty.
