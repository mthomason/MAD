**English** | [简体中文](README_zh.md) | [日本語](README_ja.md)

## Details on iCloud

It's currently prompting for user to choose an iCloud location whenever they open.  Not sure is the state is being stored.

Where to store documents?
    Let user decide?
    Once they choose, just use that location.

application:didFinishWithLaunchingWithOptions
    [[NSFileManager defaultManager] ubiquityIdentityToken]

Register for NSUbiquityIdentifierDidChangeNotification
