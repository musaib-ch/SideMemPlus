import SwiftUI
import UniformTypeIdentifiers

private enum BuildStatus {
    static let memory = "Not connected: Apple developer authentication and entitlement provisioning core required."
    static let jit = "Not connected: device pairing and a compatible JIT provider required."
    static let install = "IPA import is enabled. Code signing and installation are not connected."
}

struct DashboardView: View {
    @State private var showImporter = false
    @State private var selectedIPA: URL?
    @State private var importError: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label("SideMemPlus", systemImage: "memorychip")
                        .font(.largeTitle.bold())
                    Text("Increased Memory Limit, JIT and IPA management")
                        .foregroundStyle(.secondary)
                    Text("Development preview. Unavailable actions are deliberately disabled until integrated and tested.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("Increased Memory Limit") {
                    Label("INCREASED_MEMORY_LIMIT", systemImage: "checkmark.shield")
                        .font(.subheadline.monospaced())
                    Text(BuildStatus.memory)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button("Enable for App ID") { }
                        .disabled(true)
                }
                Section("JIT") {
                    Text(BuildStatus.jit)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button("Enable JIT") { }
                        .disabled(true)
                }
                Section("IPA files") {
                    Button {
                        showImporter = true
                    } label: {
                        Label("Import IPA", systemImage: "square.and.arrow.down")
                    }
                    if let selectedIPA {
                        Text("Selected: \(selectedIPA.lastPathComponent)")
                            .font(.footnote)
                    }
                    if let importError {
                        Text(importError).foregroundStyle(.red)
                    }
                    Text(BuildStatus.install)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button("Sign and Install") { }
                        .disabled(true)
                }
                Section("About") {
                    Link("SideInstaller", destination: URL(string: "https://github.com/FrizzleM/SideInstaller")!)
                    Link("SideStore", destination: URL(string: "https://github.com/SideStore/SideStore")!)
                    Link("StikDebug", destination: URL(string: "https://github.com/StikDebug/StikDebug")!)
                }
            }
            .navigationTitle("SideMemPlus")
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.item], allowsMultipleSelection: false) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    guard url.pathExtension.lowercased() == "ipa" else {
                        importError = "Select an IPA file."
                        return
                    }
                    selectedIPA = url
                    importError = nil
                case .failure(let error):
                    importError = error.localizedDescription
                }
            }
        }
    }
}
