//
//  MetronomeSettings.swift
//  JazzPicker
//
//  Persistent settings for metronome sound and visual feedback.
//

import SwiftUI
import Combine

enum MetronomeSoundType: String, CaseIterable, Identifiable {
    case woodBlock = "Wood Block"
    case cowbell = "Cowbell"
    case hiHat = "Hi-Hat"
    case click = "Click"
    case silent = "Silent (Haptics Only)"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .woodBlock: return "hammer.fill"
        case .cowbell: return "bell.fill"
        case .hiHat: return "circle.bottomhalf.filled"
        case .click: return "waveform"
        case .silent: return "iphone.radiowaves.left.and.right"
        }
    }
}

enum VisualPulseIntensity: String, CaseIterable, Identifiable {
    case subtle = "Subtle"
    case moderate = "Moderate"
    case dramatic = "Dramatic"

    var id: String { rawValue }

    var opacity: Double {
        switch self {
        case .subtle: return 0.25
        case .moderate: return 0.5
        case .dramatic: return 0.8
        }
    }

    var lineWidth: CGFloat {
        switch self {
        case .subtle: return 6
        case .moderate: return 10
        case .dramatic: return 16
        }
    }
}

@MainActor
class MetronomeSettings: ObservableObject {
    static let shared = MetronomeSettings()

    @AppStorage("metronome.soundType") private var soundTypeRaw: String = MetronomeSoundType.woodBlock.rawValue
    @AppStorage("metronome.visualPulseEnabled") var visualPulseEnabled: Bool = true
    @AppStorage("metronome.visualIntensity") private var visualIntensityRaw: String = VisualPulseIntensity.moderate.rawValue

    var soundType: MetronomeSoundType {
        get { MetronomeSoundType(rawValue: soundTypeRaw) ?? .woodBlock }
        set {
            soundTypeRaw = newValue.rawValue
            objectWillChange.send()
        }
    }

    var visualIntensity: VisualPulseIntensity {
        get { VisualPulseIntensity(rawValue: visualIntensityRaw) ?? .moderate }
        set {
            visualIntensityRaw = newValue.rawValue
            objectWillChange.send()
        }
    }

    private init() {}
}
