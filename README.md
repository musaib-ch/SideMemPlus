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

## Full engine experimental IPA

The `Build SideMemPlus Full Engine (experimental)` workflow checks out SideInstaller at a pinned upstream commit, compiles its Rust/iOS code with the SideMemPlus bundle ID, changes the unsigned app display name to SideMemPlus and uploads `SideMemPlus-full-experimental-unsigned.ipa`.

This is an **upstream-based experimental build**, not a complete rewritten or security-audited SideMemPlus implementation. Its interface and behavior largely remain SideInstaller's. It includes upstream Apple account authentication, entitlement support, IPA signing and install workflows, subject to their compatibility limits. A generalized JIT enabler for arbitrary apps is **not confirmed**. Neither build automatically signs with a device-trusted certificate. Never enter Apple credentials into a build log or GitHub secrets for this workflow.

Source attribution: [SideInstaller by FrizzleM](https://github.com/FrizzleM/SideInstaller), used under its noncommercial/custom license. Official SideInstaller binaries are not redistributed.
