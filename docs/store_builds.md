# EduNest Store Builds

## Google Play / CH Play

Google Play expects an Android App Bundle (`.aab`) for production releases.

```powershell
flutter build appbundle --release `
  --dart-define=EDUNEST_API_BASE_URL=https://edunest-backend-8e6z.onrender.com `
  --dart-define=EDUNEST_APP_VERSION=1.0.0+1
```

Upload this file in Play Console:

```text
build\app\outputs\bundle\release\app-release.aab
```

Release signing requires `android/key.properties` and the upload keystore. Keep both private.

## Microsoft Store

Microsoft Store expects a Windows package, not the Android `.aab` or `.apk`.

Build the Windows app first:

```powershell
flutter build windows --release `
  --dart-define=EDUNEST_API_BASE_URL=https://edunest-backend-8e6z.onrender.com `
  --dart-define=EDUNEST_APP_VERSION=1.0.0+1
```

Create the MSIX package:

```powershell
dart run msix:create
```

The `msix_config.windows_build_args` value already passes the production API URL
and app version when `msix:create` rebuilds the Windows app.

Before the final Microsoft Store upload, replace the placeholder values in
`pubspec.yaml` under `msix_config` with the exact values from Microsoft Partner
Center:

```yaml
msix_config:
  identity_name: <Partner Center package identity name>
  publisher_display_name: <Partner Center publisher display name>
  publisher: <Partner Center publisher, for example CN=...>
```

The app declares `internetClient` because EduNest connects to the backend API.
`store: true` and `sign_msix: false` are set because Microsoft Store signs the
package during ingestion.
