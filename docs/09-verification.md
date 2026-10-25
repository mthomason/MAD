## 9. Verification

The claims in §§2-5 are reproducible (run these from the repository root):

```sh
tar tjf MADDesigner/Resources/Assets/Samples.xcassets/Reports/Music.dataset/Music.mad
mkdir -p /tmp/mad && tar xjf … -C /tmp/mad
plutil -p /tmp/mad/meta.plist
file /tmp/mad/StoreContent/analyitics
```

The claims in §5 are reproducible from a device or simulator container:

```sh
ls -la ~/Library/Developer/CoreSimulator/Devices/<UDID>/data/Library/Caches/<dataTableIdHash>/
```

Any change to the format must extend the round-trip fixtures described in
`../MAD_CLI.md` §6, so that the definition in this file is pinned by a test rather than
by this prose.  The container's fixture exists as of 2026-10-16
(`../Linux/Tests/MADArchiveManagerTests.m`: unpack, repack, unpack again, member list and
bytes unchanged), and §7.2's checkpoint bit is pinned by the writer that sets it (`mad
write`).  The writer's *reproducible mode* — fixed member time, ownership 0, sorted
walk — is what makes two platforms' documents equal; it is opt-in, so an ordinary
archive still records the filesystem's metadata, and it is not a format version (the
file is v1 either way). §5 is the part with no such fixture today — the companion files are
described here from measurement, and nothing fails if the measurement stops being
true.
