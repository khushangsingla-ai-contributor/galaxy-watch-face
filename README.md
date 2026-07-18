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

## Install / preview on a device

```bash
./gradlew :faces:simple-digital:installDebug
```

Then long-press the watch face on the device to select it. A physical Galaxy
Watch 7 or a Wear OS emulator (which requires hardware/KVM acceleration) is
needed to see the rendered face.
