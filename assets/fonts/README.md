# Fonts

The UI uses the **Sora** font via the `google_fonts` package.

For offline/production builds, place the TTF files here and register them in
`pubspec.yaml` under the `fonts:` section.

Recommended files:
- `Sora-Regular.ttf`
- `Sora-Medium.ttf`
- `Sora-SemiBold.ttf`
- `Sora-Bold.ttf`

Once files are added, run:
```
flutter pub get
```

Then you can disable runtime font fetching by setting:
```
GoogleFonts.config.allowRuntimeFetching = false;
```
in `main.dart` (optional but recommended for production).
