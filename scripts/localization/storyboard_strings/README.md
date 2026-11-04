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

## The shipped languages

The five translated languages (`de`, `es`, `ja`, `pt-BR`, `zh-Hans`) carry a
file for every resource that has at least one translatable entry: the 16 app
storyboards and xibs that do, the three driver `MADCreateDocument` storyboards,
and no file where every entry is marked do-not-translate. The translations are
machine-assisted and unreviewed (D14); each generated file's header points at
the issue tracker.

The exporter's `DO NOT TRANSLATE` comment is the first layer. The translation
pass applied a second, explicit exclusion for names the exporter cannot know:
barcode symbologies such as `QR Code` and `PDF417`, the font families it does
not list, and numeric sample values. It also omitted any entry the catalog
marks `shouldTranslate: false`, and reused the catalog translation for a label
that is also an app string, so the two stay consistent.

`scripts/localization/check_translations.py` checks every translated storyboard
entry against this template: it rejects an unknown object ID, an empty value,
and a changed format specifier. CI runs it beside the audit and catalog checks.

`MADDesigner/Resources/Storyboard/de.lproj/MADQuery.strings` is the first
worked example; its German values were later folded into the full set.
