//
//  SplashHapticsPlayer.swift
//  SplashAnimation
//
//  Created by Andrei Kovryzhenko on 05.08.2026.
//

import CoreHaptics
import Foundation

private enum Constants {
    static let patternName = "splash_haptics"
    static let patternExtension = "ahap"
}

@MainActor
final class SplashHapticsPlayer {
    private var engine: CHHapticEngine?

    func play() {
        guard
            engine == nil,
            CHHapticEngine.capabilitiesForHardware().supportsHaptics,
            let patternURL = Bundle.module.url(
                forResource: Constants.patternName,
                withExtension: Constants.patternExtension
            )
        else {
            return
        }

        do {
            let engine = try CHHapticEngine()
            engine.isAutoShutdownEnabled = true
            self.engine = engine
            try engine.start()
            try engine.playPattern(from: patternURL)
        } catch {
            self.engine = nil
        }
    }
}
