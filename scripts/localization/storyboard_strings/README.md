# Storyboard and xib strings

This tree is the English source of every `Base.lproj` storyboard and xib in
the app and in the three live driver frameworks, exported with
`xcrun ibtool --export-strings-file`. It is the translator's template; it is
not compiled into anything.

Regenerate after editing a storyboard or xib (macOS only):

```sh
python3 -I scripts/localization/export_storyboard_strings.py
```

The exporter reads the barcode display names from
`MADBarcodes/.../MADBarcode.m` so a symbology name is marked automatically,
and it marks numbers, symbols, product and brand names, font names, locale
codes, and the design-time placeholders (`Item`, `Title`, `Detail`, the Lorem
ipsum body, sample values). An entry marked `DO NOT TRANSLATE` keeps its
English source verbatim. The markers are a starting point, not a promise: the
`MADBarcodeDesigner` reference tables and the sample rows in `MADStore` need a
human review before their screen is translated.

## Adding a language

`Base.lproj` is the source language, so English needs no `.strings` file. For
each language, and each resource that has translatable entries:

1. Copy the exported file as the template and translate only the entries that
   are not marked `DO NOT TRANSLATE`. Omitting a marked entry is the simplest
   way to keep it in English: `ibtool` falls back to the Base storyboard value
   for any key the language does not define.
2. Save it as `<Name>.strings` (for example `MADQuery.strings`) in a new
   `<lang>.lproj` beside the resource's `Base.lproj`.
3. Add that file to the storyboard's variant group in the owning project, so
   Xcode compiles it into the bundle. In the app project the resources are
   `MAD Designer.xcodeproj` (`PBXVariantGroup` for each storyboard and xib);
   the three driver storyboards live in `MADMySQL`, `MADPostgres`, and
   `MADTdsClient` and must be localized in their own projects, because each is
   loaded from that framework's bundle (D5).
4. Build the owning target and confirm the `<lang>.lproj/<Name>.strings` file
   is in the built bundle.

The keys are Interface Builder object IDs (`"5gw-CY-Adb.text"`). They are
stable as long as the storyboard object IDs are not regenerated, so do not
recreate a storyboard from scratch after its translations exist.

`MADDesigner/Resources/Storyboard/de.lproj/MADQuery.strings` is the first
worked example: two German entries, everything else left to the Base value.
