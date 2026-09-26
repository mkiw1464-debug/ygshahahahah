import Foundation

// MARK: - Assembly Inject Service
// Inject Assembly-CSharp-patch.bytes + localConfig.json ke Documents game
// + 50 fake decoy files untuk confuse crackers
// + auto-delete patch selepas game open (files fake kekal)

private enum _X {
    static let k: UInt8 = 0x5A
    static func d(_ b: [UInt8]) -> String {
        String(bytes: b.map { $0 ^ k }, encoding: .utf8) ?? ""
    }
}

enum AssemblyInjectService {

    // "Assembly-CSharp-patch.bytes" — XOR encoded
    private static let _patchName: [UInt8] = [
        0x1b, 0x29, 0x29, 0x3f, 0x37, 0x38, 0x36, 0x23, 0x77, 0x19, 0x09,
        0x32, 0x3b, 0x28, 0x2a, 0x77, 0x2a, 0x3b, 0x2e, 0x39, 0x32, 0x74,
        0x38, 0x23, 0x2e, 0x3f, 0x29
    ]

    // "localConfig.json"
    private static let _configName: [UInt8] = [
        0x36, 0x35, 0x39, 0x3b, 0x36, 0x19, 0x35, 0x34, 0x3c, 0x33, 0x3d,
        0x74, 0x30, 0x29, 0x35, 0x34
    ]

    static var patchFileName:  String { _X.d(_patchName) }
    static var configFileName: String { _X.d(_configName) }

    // MARK: - Target directory = Documents/

    static func documentsDir(containerPath: String) -> URL {
        URL(fileURLWithPath: containerPath).appendingPathComponent("Documents")
    }

    // MARK: - Inject marker path

    private static func markerURL(containerPath: String) -> URL {
        documentsDir(containerPath: containerPath)
            .appendingPathComponent(".\(patchFileName).ok")
    }

    // MARK: - Is injected?

    static func isInjected(game: FFGame) -> Bool {
        guard let path = ContainerStore.resolveAppContainerPath(bundleID: game.bundleID) else {
            return false
        }
        return FileManager.default.fileExists(atPath: markerURL(containerPath: path).path)
    }

    // MARK: - Inject

    static func inject(game: FFGame) async throws {
        let bundleID = game.bundleID
        guard let containerPath = ContainerStore.resolveAppContainerPath(bundleID: bundleID) else {
            throw AssemblyError.containerNotFound
        }

        let handle = ContainerStore.grantContainerAccess(containerPath)
        defer { if handle >= 0 { bad_query_release(handle) } }

        let fm  = FileManager.default
        let dir = documentsDir(containerPath: containerPath)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)

        // --- 1. Inject Assembly-CSharp-patch.bytes ---
        guard let patchURL = Bundle.main.url(forResource: "Assembly-CSharp-patch", withExtension: "bytes"),
              let patchData = try? Data(contentsOf: patchURL) else {
            throw AssemblyError.patchNotInBundle
        }
        try writeAtomic(data: patchData, to: dir.appendingPathComponent(patchFileName))

        // --- 2. Inject localConfig.json ---
        let localConfigData: Data
        if let cfgURL = Bundle.main.url(forResource: "localConfig", withExtension: "json"),
           let data = try? Data(contentsOf: cfgURL) {
            localConfigData = data
        } else {
            // fallback hardcode
            localConfigData = Data(#"{"testCodePatch":true}"#.utf8)
        }
        try writeAtomic(data: localConfigData, to: dir.appendingPathComponent(configFileName))

        // --- 3. 50 fake decoy files (empty) ---
        for i in 1...50 {
            let fakeURL = dir.appendingPathComponent("\(patchFileName)\(i)")
            fm.createFile(atPath: fakeURL.path, contents: Data())
        }

        // --- 4. Write injected marker ---
        fm.createFile(atPath: markerURL(containerPath: containerPath).path, contents: Data())
    }

    // MARK: - Auto-delete patch after open (fakes kekal)

    static func deletePatchAfterOpen(game: FFGame) {
        guard let containerPath = ContainerStore.resolveAppContainerPath(bundleID: game.bundleID) else {
            return
        }
        let dir = documentsDir(containerPath: containerPath)
        let fm  = FileManager.default

        DispatchQueue.global().asyncAfter(deadline: .now() + 2.5) {
            let handle = ContainerStore.grantContainerAccess(containerPath)
            defer { if handle >= 0 { bad_query_release(handle) } }

            // buang patch sebenar
            try? fm.removeItem(at: dir.appendingPathComponent(patchFileName))
            // buang marker
            try? fm.removeItem(at: markerURL(containerPath: containerPath))
            // localConfig boleh kekal — tak ada sensitive content
        }
    }

    // MARK: - Remove all (termasuk fakes)

    static func removeAll(game: FFGame) throws {
        guard let containerPath = ContainerStore.resolveAppContainerPath(bundleID: game.bundleID) else {
            throw AssemblyError.containerNotFound
        }
        let handle = ContainerStore.grantContainerAccess(containerPath)
        defer { if handle >= 0 { bad_query_release(handle) } }

        let fm  = FileManager.default
        let dir = documentsDir(containerPath: containerPath)

        try? fm.removeItem(at: dir.appendingPathComponent(patchFileName))
        try? fm.removeItem(at: dir.appendingPathComponent(configFileName))
        try? fm.removeItem(at: markerURL(containerPath: containerPath))
        for i in 1...50 {
            try? fm.removeItem(at: dir.appendingPathComponent("\(patchFileName)\(i)"))
        }
    }

    // MARK: - Atomic write helper

    private static func writeAtomic(data: Data, to url: URL) throws {
        let tmp = url.deletingLastPathComponent()
            .appendingPathComponent(".\(UUID().uuidString).tmp")
        guard FileManager.default.createFile(atPath: tmp.path, contents: data) else {
            throw AssemblyError.writeFailed
        }
        guard rename(tmp.path, url.path) == 0 else {
            try? FileManager.default.removeItem(at: tmp)
            throw AssemblyError.writeFailed
        }
    }
}

// MARK: - Errors

enum AssemblyError: LocalizedError {
    case containerNotFound
    case patchNotInBundle
    case writeFailed

    var errorDescription: String? {
        switch self {
        case .containerNotFound: return "Game container not found"
        case .patchNotInBundle:  return "Patch file not found in app bundle"
        case .writeFailed:       return "Failed to write file"
        }
    }
}
