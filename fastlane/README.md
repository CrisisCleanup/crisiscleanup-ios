fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios setup_keychain

```sh
[bundle exec] fastlane ios setup_keychain
```

Setup codesigning keychain.

### ios authenticate

```sh
[bundle exec] fastlane ios authenticate
```

Authenticate with app store connect api.

### ios certificates

```sh
[bundle exec] fastlane ios certificates
```

Install certifications + provisioning profiles.

### ios decrypt

```sh
[bundle exec] fastlane ios decrypt
```

Decrypt Configs

### ios encrypt

```sh
[bundle exec] fastlane ios encrypt
```

Encrypt Configs (Update)

### ios inject_config

```sh
[bundle exec] fastlane ios inject_config
```

Inject plist config

### ios privacy

```sh
[bundle exec] fastlane ios privacy
```

Upload Privacy

### ios check

```sh
[bundle exec] fastlane ios check
```

Check metadata

### ios build

```sh
[bundle exec] fastlane ios build
```

Build App

### ios test

```sh
[bundle exec] fastlane ios test
```

Run Tests

### ios dev

```sh
[bundle exec] fastlane ios dev
```

Build Development App

### ios release

```sh
[bundle exec] fastlane ios release
```

Build Release App

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Publish Beta Release

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
