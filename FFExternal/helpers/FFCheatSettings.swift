import Foundation
import SwiftUI

// MARK: - Cheat Settings (shared state, persisted via UserDefaults)

final class FFCheatSettings: ObservableObject {

    static let shared = FFCheatSettings()

    // MARK: - ESP
    @Published var espEnabled:     Bool { didSet { save() } }
    @Published var espLine:        Bool { didSet { save() } }
    @Published var espBox:         Bool { didSet { save() } }
    @Published var espHealth:      Bool { didSet { save() } }
    @Published var espDistance:    Bool { didSet { save() } }
    @Published var espPlayerCount: Bool { didSet { save() } }

    // MARK: - AIM
    @Published var aimEnabled:       Bool   { didSet { save() } }
    @Published var aimType:          AimType   { didSet { save() } }
    @Published var aimTarget:        AimTarget { didSet { save() } }
    @Published var aimMode:          AimMode   { didSet { save() } }
    @Published var aimIgnoreKnock:   Bool   { didSet { save() } }
    @Published var aimDrawFOV:       Bool   { didSet { save() } }
    @Published var aimFOVValue:      Double { didSet { save() } }
    @Published var aimFOVColor:      Color  { didSet { save() } }

    // MARK: - MISC (dari Assembly patch)
    @Published var fastReload:  Bool { didSet { save() } }
    @Published var fastMedkit:  Bool { didSet { save() } }
    @Published var fakeName:    Bool { didSet { save() } }

    // MARK: - Keys
    private enum K {
        static let espEnabled     = "x.esp.en"
        static let espLine        = "x.esp.ln"
        static let espBox         = "x.esp.bx"
        static let espHealth      = "x.esp.hp"
        static let espDistance    = "x.esp.ds"
        static let espPlayerCount = "x.esp.pc"
        static let aimEnabled     = "x.aim.en"
        static let aimType        = "x.aim.ty"
        static let aimTarget      = "x.aim.tg"
        static let aimMode        = "x.aim.md"
        static let aimIgnoreKnock = "x.aim.ik"
        static let aimDrawFOV     = "x.aim.df"
        static let aimFOVValue    = "x.aim.fv"
        static let aimFOVColorR   = "x.aim.cr"
        static let aimFOVColorG   = "x.aim.cg"
        static let aimFOVColorB   = "x.aim.cb"
        static let fastReload     = "x.misc.fr"
        static let fastMedkit     = "x.misc.fm"
        static let fakeName       = "x.misc.fn"
    }

    private init() {
        let d = UserDefaults.standard
        espEnabled     = d.bool(forKey: K.espEnabled)
        espLine        = d.bool(forKey: K.espLine)
        espBox         = d.bool(forKey: K.espBox)
        espHealth      = d.bool(forKey: K.espHealth)
        espDistance    = d.bool(forKey: K.espDistance)
        espPlayerCount = d.bool(forKey: K.espPlayerCount)
        aimEnabled     = d.bool(forKey: K.aimEnabled)
        aimType        = AimType(rawValue: d.string(forKey: K.aimType) ?? "") ?? .aimbot
        aimTarget      = AimTarget(rawValue: d.string(forKey: K.aimTarget) ?? "") ?? .head
        aimMode        = AimMode(rawValue: d.string(forKey: K.aimMode) ?? "") ?? .always
        aimIgnoreKnock = d.bool(forKey: K.aimIgnoreKnock)
        aimDrawFOV     = d.bool(forKey: K.aimDrawFOV)
        aimFOVValue    = d.object(forKey: K.aimFOVValue) != nil ? d.double(forKey: K.aimFOVValue) : 80.0
        let r = d.object(forKey: K.aimFOVColorR) != nil ? d.double(forKey: K.aimFOVColorR) : 0.2
        let g = d.object(forKey: K.aimFOVColorG) != nil ? d.double(forKey: K.aimFOVColorG) : 0.8
        let b = d.object(forKey: K.aimFOVColorB) != nil ? d.double(forKey: K.aimFOVColorB) : 1.0
        aimFOVColor    = Color(red: r, green: g, blue: b)
        fastReload     = d.bool(forKey: K.fastReload)
        fastMedkit     = d.bool(forKey: K.fastMedkit)
        fakeName       = d.bool(forKey: K.fakeName)
    }

    private func save() {
        let d = UserDefaults.standard
        d.set(espEnabled,     forKey: K.espEnabled)
        d.set(espLine,        forKey: K.espLine)
        d.set(espBox,         forKey: K.espBox)
        d.set(espHealth,      forKey: K.espHealth)
        d.set(espDistance,    forKey: K.espDistance)
        d.set(espPlayerCount, forKey: K.espPlayerCount)
        d.set(aimEnabled,     forKey: K.aimEnabled)
        d.set(aimType.rawValue,    forKey: K.aimType)
        d.set(aimTarget.rawValue,  forKey: K.aimTarget)
        d.set(aimMode.rawValue,    forKey: K.aimMode)
        d.set(aimIgnoreKnock, forKey: K.aimIgnoreKnock)
        d.set(aimDrawFOV,     forKey: K.aimDrawFOV)
        d.set(aimFOVValue,    forKey: K.aimFOVValue)
        d.set(fastReload,     forKey: K.fastReload)
        d.set(fastMedkit,     forKey: K.fastMedkit)
        d.set(fakeName,       forKey: K.fakeName)
        // FOV color
        if let c = UIColor(aimFOVColor).cgColor.components {
            d.set(Double(c[0]), forKey: K.aimFOVColorR)
            d.set(Double(c[1]), forKey: K.aimFOVColorG)
            d.set(Double(c[2]), forKey: K.aimFOVColorB)
        }
    }

    func resetAll() {
        espEnabled = false; espLine = false; espBox = false
        espHealth = false; espDistance = false; espPlayerCount = false
        aimEnabled = false; aimType = .aimbot; aimTarget = .head
        aimMode = .always; aimIgnoreKnock = false; aimDrawFOV = false
        aimFOVValue = 80.0; aimFOVColor = Color(red: 0.2, green: 0.8, blue: 1.0)
        fastReload = false; fastMedkit = false; fakeName = false
    }
}

// MARK: - Enums

enum AimType: String, CaseIterable, Identifiable {
    case aimbot    = "aimbot"
    case aimSilent = "aimsilent"
    var id: String { rawValue }
    var label: String {
        switch self {
        case .aimbot:    return "Aimbot"
        case .aimSilent: return "Aim Silent"
        }
    }
}

enum AimTarget: String, CaseIterable, Identifiable {
    case head  = "head"
    case neck  = "neck"
    case body  = "body"
    var id: String { rawValue }
    var label: String {
        switch self {
        case .head:  return "Head"
        case .neck:  return "Neck"
        case .body:  return "Body"
        }
    }
}

enum AimMode: String, CaseIterable, Identifiable {
    case always  = "always"
    case firing  = "firing"
    case scoping = "scoping"
    var id: String { rawValue }
    var label: String {
        switch self {
        case .always:  return "Always"
        case .firing:  return "Firing"
        case .scoping: return "Scoping"
        }
    }
}
