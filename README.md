# galaxy-watch-face

Watch faces for the **Samsung Galaxy Watch 7** (Wear OS 5), built with the
[Watch Face Format (WFF)](https://developer.android.com/training/wearables/wff) —
the declarative, resource-only XML format that is required for all Wear OS watch
faces as of January 2026.

Each watch face is an independent, code-free Android module: all of its content
lives in `res/` (with the face definition in `res/raw/watchface.xml`) and the
manifest declares `android:hasCode="false"`.

## Repository layout

```
faces/
  simple-digital/        # first watch face (starter template)
    src/main/
      AndroidManifest.xml
      res/raw/watchface.xml        # the watch face definition (WFF XML)
      res/xml/watch_face_info.xml  # metadata (preview, etc.)
      res/drawable/preview.png     # required preview image
      res/values/strings.xml
scripts/
  wff-validate.sh        # validate every face against the official WFF validator
```

Add a new watch face by creating another module under `faces/` and registering
it in `settings.gradle`.

## Requirements

- JDK 17+ (JDK 21 is used in the cloud dev VM)
- Android SDK with `platforms;android-34`, `build-tools;34.0.0`, `platform-tools`
- Gradle wrapper is included (`./gradlew`)

Point Gradle at your SDK by creating `local.properties`:

```
sdk.dir=/path/to/android-sdk
```

## Build

```bash
# Build a specific face (debug)
./gradlew :faces:simple-digital:assembleDebug

# Release AAB/APK
./gradlew :faces:simple-digital:assembleRelease
```

The APK is written to `faces/<name>/build/outputs/apk/`.

## Lint

```bash
./gradlew :faces:simple-digital:lintDebug
```

## Validate the Watch Face Format XML

```bash
./scripts/wff-validate.sh 2   # 2 = WFF version (Wear OS 5 / Galaxy Watch 7)
```

This uses the official [WFF validator](https://github.com/google/watchface).
See the script header for one-time setup of the validator jar.

## Gallery

A searchable gallery of all faces is generated under `docs/` by the `pre-commit`
hook (`node scripts/generate-gallery.mjs`). Each card links to the face's source
module, build command, and the latest release APK on GitHub. On `main`, the
`deploy-pages` workflow publishes `docs/` to GitHub Pages whenever it changes
(set Pages source to "GitHub Actions").

## Build installable APK artifacts

```bash
# Build release APKs for every face into dist/ (also writes dist/manifest.json)
./scripts/build-artifacts.sh
```

## Publish a release

Push a git tag to build APKs in CI and attach them to a GitHub Release:

```bash
git tag v1.0.0
git push origin v1.0.0
```

The `release` workflow builds every face and uploads `dist/<id>.apk` as release
assets. Gallery download links use `/releases/latest/download/<id>.apk`, so they
automatically point at the newest tag without regenerating the gallery.

## Install / preview on a device

```bash
./gradlew :faces:simple-digital:installDebug
```

Then long-press the watch face on the device to select it. A physical Galaxy
Watch 7 or a Wear OS emulator (which requires hardware/KVM acceleration) is
needed to see the rendered face.
