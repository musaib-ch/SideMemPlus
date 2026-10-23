import SwiftUI
import UniformTypeIdentifiers

enum SideMemCapability: String, CaseIterable {
    case memory = "Increased Memory Limit"
    case jit = "JIT"
    case installation = "IPA Installation"
}

struct ImportedIPA: Identifiable {
    let id = UUID()
    let filename: String
    let fileURL: URL
}

@MainActor
final class SideMemStore: ObservableObject {
    @Published var importedApps: [ImportedIPA] = []
    @Published var message: String?
    @Published var isImporting = false

    func importIPA(from url: URL) {
        guard url.pathExtension.lowercased() == "ipa" else {
            message = "Please select an .ipa file."
            return
        }
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        do {
            let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("ImportedIPAs", isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let destination = directory.appendingPathComponent(UUID().uuidString + "-" + url.lastPathComponent)
            try FileManager.default.copyItem(at: url, to: destination)
            importedApps.append(ImportedIPA(filename: url.lastPathComponent, fileURL: destination))
            message = "IPA securely copied into this app's documents. Signing and installation are not yet connected."
        } catch {
            message = "Import failed: \(error.localizedDescription)"
        }
    }
}

struct DashboardView: View {
    @StateObject private var store = SideMemStore()
    @State private var importing = false

    var body: some View {
        TabView {
            NavigationStack {
                List {
                    Section {
                        Label("SideMemPlus", systemImage: "memorychip")
                            .font(.title.bold())
                        Text("Your IPA library, memory entitlement preparation and JIT tools in one place.")
                            .foregroundStyle(.secondary)
                    }
                    Section("My IPAs") {
                        Button { importing = true } label: {
                            Label("Import IPA", systemImage: "plus.circle.fill")
                        }
                        ForEach(store.importedApps) { ipa in
                            Label(ipa.filename, systemImage: "shippingbox")
                        }
                        if store.importedApps.isEmpty {
                            Text("No IPAs imported yet.")
                                .foregroundStyle(.secondary)
                        }
                    }
                    Section("Signing status") {
                        Label("Apple developer authentication: not connected", systemImage: "lock.shield")
                        Label("Increased Memory Limit: not connected", systemImage: "memorychip")
                        Text("The memory capability must be enabled for the app's registered App ID before a compatible provisioning profile is generated. A valid profile is required for signing.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    if let message = store.message {
                        Section("Activity") { Text(message).font(.footnote) }
                    }
                }
                .navigationTitle("Apps")
                .fileImporter(isPresented: $importing, allowedContentTypes: [.item]) { result in
                    switch result {
                    case .success(let url): store.importIPA(from: url)
                    case .failure(let error): store.message = error.localizedDescription
                    }
                }
            }
            .tabItem { Label("Apps", systemImage: "square.stack.3d.up") }

            NavigationStack {
                List {
                    Section("JIT enabler") {
                        Label("Not connected", systemImage: "bolt.slash")
                        Text("A paired device connection, valid pairing record, and iOS-version-compatible debugger backend are required. SideMemPlus will not falsely report that JIT is enabled.")
                            .foregroundStyle(.secondary)
                    }
                }
                .navigationTitle("JIT")
            }
            .tabItem { Label("JIT", systemImage: "bolt") }

            NavigationStack {
                List {
                    Section("Security") {
                        Label("Apple credentials are not requested in this preview", systemImage: "key")
                        Label("Imported IPAs remain on device", systemImage: "iphone")
                        Label("No pairing records are transmitted", systemImage: "shield")
                    }
                    Section("References") {
                        Link("SideInstaller by FrizzleM", destination: URL(string: "https://github.com/FrizzleM/SideInstaller")!)
                        Link("SideStore", destination: URL(string: "https://github.com/SideStore/SideStore")!)
                        Link("StikDebug", destination: URL(string: "https://github.com/StikDebug/StikDebug")!)
                    }
                }
                .navigationTitle("Settings")
            }
            .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
