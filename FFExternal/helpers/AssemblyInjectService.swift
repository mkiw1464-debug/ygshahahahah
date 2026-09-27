import Foundation

// MARK: - Assembly Inject Service
// patch.dat + cfg.dat dalam bundle adalah XOR-encrypted
// decrypt dalam memory sahaja, tulis terus ke game, clear memory

private enum _K {
    // XOR key 32-byte -- obfuscated
    static let v: [UInt8] = [
        0x2A, 0xCB, 0xE3, 0x9C, 0xDA, 0x13, 0xA0, 0x23,
        0x13, 0x1F, 0x14, 0x3B, 0x5E, 0x05, 0x71, 0xAA,
        0x51, 0x6F, 0xB8, 0xB2, 0xA4, 0x43, 0x4E, 0xDA,
        0xC5, 0xE1, 0x74, 0x33, 0x7F, 0xEE, 0xD8, 0x7B
    ]

    static func dec(_ data: Data) -> Data {
        var out = Data(count: data.count)
        let kl = v.count
        data.withUnsafeBytes { src in
            out.withUnsafeMutableBytes { dst in
                for i in 0 ..< data.count {
                    dst[i] = src.load(fromByteOffset: i, as: UInt8.self) ^ v[i % kl]
                }
            }
        }
        return out
    }
}

private enum _N {
    static let k: UInt8 = 0x5A
    static func d(_ b: [UInt8]) -> String {
        String(bytes: b.map { $0 ^ k }, encoding: .utf8) ?? ""
    }
    // "Assembly-CSharp-patch.bytes"
    static let patch: String = d([
        0x1b,0x29,0x29,0x3f,0x37,0x38,0x36,0x23,0x77,0x19,0x09,
        0x32,0x3b,0x28,0x2a,0x77,0x2a,0x3b,0x2e,0x39,0x32,0x74,
        0x38,0x23,0x2e,0x3f,0x29
    ])
    // "localConfig.json"
    static let cfg: String = d([
        0x36,0x35,0x39,0x3b,0x36,0x19,0x35,0x34,0x3c,0x33,0x3d,
        0x74,0x30,0x29,0x35,0x34
    ])
    // "Documents"
    static let docs: String = d([0x1e,0x35,0x39,0x2f,0x37,0x3f,0x34,0x2e,0x29])
}

enum AssemblyInjectService {

    static var patchFileName: String  { _N.patch }
    static var configFileName: String { _N.cfg   }

    static func documentsDir(containerPath: String) -> URL {
        URL(fileURLWithPath: containerPath).appendingPathComponent(_N.docs)
    }

    private static func markerURL(containerPath: String) -> URL {
        documentsDir(containerPath: containerPath)
            .appendingPathComponent(".\(patchFileName).ok")
    }

    static func isInjected(game: FFGame) -> Bool {
        guard let p = ContainerStore.resolveAppContainerPath(bundleID: game.bundleID) else { return false }
        return FileManager.default.fileExists(atPath: markerURL(containerPath: p).path)
    }

    // MARK: - Inject

    static func inject(game: FFGame) async throws {
        guard let containerPath = ContainerStore.resolveAppContainerPath(bundleID: game.bundleID) else {
            throw AssemblyError.containerNotFound
        }
        let handle = ContainerStore.grantContainerAccess(containerPath)
        defer { if handle >= 0 { bad_query_release(handle) } }

        let fm  = FileManager.default
        let dir = documentsDir(containerPath: containerPath)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)

        // -- 1. Decrypt patch.dat in memory, write, clear --
        guard let encPatchURL = Bundle.main.url(forResource: "patch", withExtension: "dat"),
              var encPatchData = try? Data(contentsOf: encPatchURL) else {
            throw AssemblyError.patchNotInBundle
        }
        let patchData = _K.dec(encPatchData)
        encPatchData.resetBytes(in: 0 ..< encPatchData.count) // wipe encrypted copy

        try writeAtomic(data: patchData, to: dir.appendingPathComponent(patchFileName))

        // -- 2. Decrypt cfg.dat in memory, write --
        if let encCfgURL = Bundle.main.url(forResource: "cfg", withExtension: "dat"),
           let encCfgData = try? Data(contentsOf: encCfgURL) {
            let cfgData = _K.dec(encCfgData)
            try? writeAtomic(data: cfgData, to: dir.appendingPathComponent(configFileName))
        } else {
            let fallback = Data(#"{"testCodePatch":true}"#.utf8)
            try? writeAtomic(data: fallback, to: dir.appendingPathComponent(configFileName))
        }

        // -- 3. 50 fake decoy files --
        for i in 1...50 {
            fm.createFile(atPath: dir.appendingPathComponent("\(patchFileName)\(i)").path,
                          contents: Data())
        }

        // -- 4. Write injected marker --
        fm.createFile(atPath: markerURL(containerPath: containerPath).path, contents: Data())
    }

    // MARK: - Delete patch after open (fakes kekal)

    static func deletePatchAfterOpen(game: FFGame) {
        guard let cp = ContainerStore.resolveAppContainerPath(bundleID: game.bundleID) else { return }
        let dir = documentsDir(containerPath: cp)
        DispatchQueue.global().asyncAfter(deadline: .now() + 2.5) {
            let h = ContainerStore.grantContainerAccess(cp)
            defer { if h >= 0 { bad_query_release(h) } }
            try? FileManager.default.removeItem(at: dir.appendingPathComponent(patchFileName))
            try? FileManager.default.removeItem(at: markerURL(containerPath: cp))
        }
    }

    // MARK: - Remove all

    static func removeAll(game: FFGame) throws {
        guard let cp = ContainerStore.resolveAppContainerPath(bundleID: game.bundleID) else {
            throw AssemblyError.containerNotFound
        }
        let h = ContainerStore.grantContainerAccess(cp)
        defer { if h >= 0 { bad_query_release(h) } }
        let dir = documentsDir(containerPath: cp)
        try? FileManager.default.removeItem(at: dir.appendingPathComponent(patchFileName))
        try? FileManager.default.removeItem(at: dir.appendingPathComponent(configFileName))
        try? FileManager.default.removeItem(at: markerURL(containerPath: cp))
        for i in 1...50 {
            try? FileManager.default.removeItem(
                at: dir.appendingPathComponent("\(patchFileName)\(i)"))
        }
    }

    // MARK: - Atomic write

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

enum AssemblyError: LocalizedError {
    case containerNotFound
    case patchNotInBundle
    case writeFailed

    var errorDescription: String? {
        switch self {
        case .containerNotFound: return "Game container not found"
        case .patchNotInBundle:  return "Patch data not found"
        case .writeFailed:       return "Failed to write file"
        }
    }
}
