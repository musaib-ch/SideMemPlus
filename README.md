# SideMemPlus iOS

Standalone SwiftUI development scaffold for Increased Memory Limit, JIT, and IPA management.

## Currently implemented
- SideMemPlus dashboard and IPA file import picker.
- Buildable XcodeGen project with iOS 17.4+ deployment target.
- GitHub Actions workflow to produce an **unsigned preview IPA**.

## Not implemented
- Apple developer sign-in, entitlement enablement and profile download.
- IPA signing or installation.
- Device pairing and JIT activation.

The disabled controls intentionally do not pretend to perform unavailable actions.

## Build
Open GitHub Actions > Build SideMemPlus IPA preview > Run workflow, or push to main. Download the SideMemPlus-preview-unsigned artifact. It needs code signing to install.

## References and licenses
- https://github.com/FrizzleM/SideInstaller
- https://github.com/SideStore/SideStore
- https://github.com/StikDebug/StikDebug

No code from these upstream projects is included. Review their licenses before integrating. Never upload Apple credentials or pairing records to GitHub Actions.
