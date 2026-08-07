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

### ios sync_signing

```sh
[bundle exec] fastlane ios sync_signing
```

Validate App Store Connect configuration

### ios certificates_development

```sh
[bundle exec] fastlane ios certificates_development
```

Validate development signing configuration

### ios certificates_appstore

```sh
[bundle exec] fastlane ios certificates_appstore
```

Validate App Store signing configuration

### ios certificates_all

```sh
[bundle exec] fastlane ios certificates_all
```



### ios zero_touch_certificates

```sh
[bundle exec] fastlane ios zero_touch_certificates
```

ZERO-TOUCH CERTIFICATE LIFECYCLE

### ios build_development

```sh
[bundle exec] fastlane ios build_development
```

Build iOS app for development without code signing

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Upload to TestFlight using automatic signing

### ios test_and_build

```sh
[bundle exec] fastlane ios test_and_build
```

Run tests and build debug version

### ios verify_metadata

```sh
[bundle exec] fastlane ios verify_metadata
```

Push metadata/screenshots to App Store Connect without submitting for review

### ios submit_to_app_store

```sh
[bundle exec] fastlane ios submit_to_app_store
```

Submit app to App Store Review

### ios promote_to_app_store

```sh
[bundle exec] fastlane ios promote_to_app_store
```

Promote TestFlight build to App Store

### ios manage_beta_groups

```sh
[bundle exec] fastlane ios manage_beta_groups
```

Manage TestFlight beta groups

### ios full_release_pipeline

```sh
[bundle exec] fastlane ios full_release_pipeline
```

Complete automated release pipeline: TestFlight → App Store

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
