# SideMemPlus

Independent native SwiftUI iOS app for IPA management, with planned Increased Memory Limit signing and JIT integration.

## Implemented
- Original three-tab user interface: Apps, JIT, Settings
- IPA import to the app's Documents directory
- GitHub Actions unsigned iOS IPA build

## Not yet implemented
- Apple account authentication and 2FA
- Apple developer portal App ID capability activation (`INCREASED_MEMORY_LIMIT`)
- Provisioning profile issuance, signing or IPA installation
- Pairing and JIT activation

The app does not claim these operations work until implemented and device-tested. The earlier workflow that rebranded upstream SideInstaller was removed. Old artifacts from past builds may still be visible, but they are not independent SideMemPlus applications.

## Upstream references
- SideInstaller by FrizzleM: https://github.com/FrizzleM/SideInstaller
- SideStore: https://github.com/SideStore/SideStore
- StikDebug: https://github.com/StikDebug/StikDebug

Source code from these projects has not been copied into this independent scaffold. Before implementing platform functionality, assess their respective licenses, Apple service compatibility and security risks.

## Build
Go to Actions > Build SideMemPlus IPA preview. A successful run offers an unsigned IPA artifact; it requires appropriate signing before installation.
