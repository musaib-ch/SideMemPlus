import Foundation
import SwiftUI
import UIKit
import SideInstallerFFI

struct RegisteredApp: Decodable, Identifiable {
    let appIdId: String
    let identifier: String
    let name: String
    var id: String { appIdId }
    enum CodingKeys: String, CodingKey {
        case appIdId = "app_id_id"
        case identifier, name
    }
}
struct CapabilityReply: Decodable {
    let capability: String
    let ok: Bool
    let error: String
}

// Called on the native library's sign-in thread. Never dispatch this callback
// synchronously to the main thread while it is waiting on the native operation.
private let verifyCallback: SITwoFactorCb = { _, _, buffer, length in
    guard let buffer, length > 0 else { return 0 }
    let semaphore = DispatchSemaphore(value: 0)
    var answer: String?
    DispatchQueue.main.async {
        let alert = UIAlertController(title: "Apple Verification", message: "Enter the six-digit code sent by Apple. Do not share this code.", preferredStyle: .alert)
        alert.addTextField { field in
            field.keyboardType = .numberPad
            field.placeholder = "Verification code"
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in semaphore.signal() })
        alert.addAction(UIAlertAction(title: "Continue", style: .default) { _ in
            let code = alert.textFields?.first?.text ?? ""
            if code.count == 6 && code.allSatisfy({ $0.isNumber }) {
                if let data = try? JSONSerialization.data(withJSONObject: ["action": "code", "code": code]),
                   let json = String(data: data, encoding: .utf8) {
                    answer = json
                }
            }
            semaphore.signal()
        })
        let root = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })?.rootViewController
        if let root {
            var presenter = root
            while let next = presenter.presentedViewController { presenter = next }
            presenter.present(alert, animated: true)
        } else {
            semaphore.signal()
        }
    }
    semaphore.wait()
    guard let answer else { return 0 }
    let bytes = Array(answer.utf8CString)
    guard bytes.count <= length else { return 0 }
    for i in bytes.indices { buffer[i] = bytes[i] }
    return 1
}

private func takeString(_ ptr: UnsafeMutablePointer<CChar>?) -> String {
    guard let ptr else { return "" }
    let value = String(cString: ptr)
    si_string_free(ptr)
    return value
}

final class MemoryCapabilityManager: ObservableObject {
    @Published var apps: [RegisteredApp] = []
    @Published var selected: String = ""
    @Published var result = "Sign in to load your registered App IDs."
    @Published var working = false
    private let queue = DispatchQueue(label: "sidememplus.memory.capabilities")
    private var session: OpaquePointer?

    deinit {
        if let session { si_cert_session_free(session) }
    }

    func connect(appleID: String, password: String, anisette: String) {
        guard !working, !appleID.isEmpty, !password.isEmpty, anisette.hasPrefix("https://") else {
            result = "Enter your Apple ID, password, and an HTTPS anisette service URL."
            return
        }
        working = true
        result = "Authenticating with Apple developer services..."
        queue.async { [self] in
            var ptr: OpaquePointer?
            var summary: UnsafeMutablePointer<CChar>?
            var error: UnsafeMutablePointer<CChar>?
            let storage = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            try? FileManager.default.createDirectory(at: storage, withIntermediateDirectories: true)
            let rc = si_cert_signin(appleID, password, anisette, "SideMemPlus", storage.path,
                                    verifyCallback, nil, &ptr, &summary, &error)
            let description = takeString(summary)
            let failure = takeString(error)
            guard rc == 0, let ptr else {
                DispatchQueue.main.async { self.result = failure.isEmpty ? "Apple authentication failed (\(rc))." : failure; self.working = false }
                return
            }
            if let old = self.session { si_cert_session_free(old) }
            self.session = ptr
            self.loadList(session: ptr, description: description)
        }
    }

    private func loadList(session: OpaquePointer, description: String) {
        var json: UnsafeMutablePointer<CChar>?
        var error: UnsafeMutablePointer<CChar>?
        let rc = si_appid_list(session, &json, &error)
        let payload = takeString(json)
        let failure = takeString(error)
        let decoded = try? JSONDecoder().decode([RegisteredApp].self, from: Data(payload.utf8))
        DispatchQueue.main.async {
            self.apps = decoded ?? []
            self.selected = self.apps.first?.id ?? ""
            self.result = rc == 0 ? "Connected: \(description). Select an App ID." : "Loading apps failed: \(failure)"
            self.working = false
        }
    }

    func enableMemory() {
        guard !working, let session, !selected.isEmpty else { return }
        let id = selected
        working = true
        result = "Requesting Increased Memory Limit from Apple..."
        queue.async { [self] in
            var json: UnsafeMutablePointer<CChar>?
            var error: UnsafeMutablePointer<CChar>?
            let rc = si_appid_enable(session, id, "INCREASED_MEMORY_LIMIT", &json, &error)
            let payload = takeString(json)
            let failure = takeString(error)
            let reply = try? JSONDecoder().decode([CapabilityReply].self, from: Data(payload.utf8))
            let first = reply?.first
            DispatchQueue.main.async {
                if rc == 0 && first?.ok == true {
                    self.result = "Apple accepted Increased Memory Limit. Regenerate the provisioning profile, then re-sign and reinstall the IPA for this App ID."
                } else {
                    self.result = "Not enabled: " + (first?.error ?? (failure.isEmpty ? "Apple did not grant this capability." : failure))
                }
                self.working = false
            }
        }
    }
}

struct MemoryCapabilityView: View {
    @StateObject private var manager = MemoryCapabilityManager()
    @State private var appleID = ""
    @State private var password = ""
    @State private var anisette = ""

    var body: some View {
        Form {
            Section("Apple developer account") {
                TextField("Apple ID", text: $appleID)
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                SecureField("Password", text: $password)
                    .textContentType(.password)
                TextField("HTTPS anisette service URL", text: $anisette)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                Button("Sign in and load App IDs") {
                    manager.connect(appleID: appleID, password: password, anisette: anisette)
                    password = ""
                }
                .disabled(manager.working)
            }
            Section("Increased Memory Limit") {
                if !manager.apps.isEmpty {
                    Picker("App ID", selection: $manager.selected) {
                        ForEach(manager.apps) { app in
                            Text(app.name.isEmpty ? app.identifier : app.name)
                                .tag(app.id)
                        }
                    }
                    Button("Enable Increased Memory Limit") { manager.enableMemory() }
                        .disabled(manager.working || manager.selected.isEmpty)
                } else {
                    Text("Sign in to select a registered App ID.")
                }
                Text("This updates an App ID capability, not an already-installed app. A refreshed provisioning profile and new IPA signature are required.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Section("Result") {
                if manager.working { ProgressView() }
                Text(manager.result).font(.footnote)
            }
            Section("Privacy") {
                Text("Credentials are used for this sign-in attempt and are not stored by the SwiftUI screen. The Rust developer-services library and your selected anisette provider process authentication data. Only use a trusted provider.")
                    .font(.footnote)
            }
        }
        .navigationTitle("Memory Limit")
    }
}
