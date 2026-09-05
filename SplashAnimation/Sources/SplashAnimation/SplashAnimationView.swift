//
//  SplashAnimationView.swift
//  SplashAnimation
//
//  Created by Andrei Kovryzhenko on 31.07.2026.
//

import Lottie
import SwiftUI

private enum Constants {
    static let animationName = "splash_animation"
}

@MainActor
public struct SplashAnimationView: View {
    private static let animation = LottieAnimation.named(
        Constants.animationName,
        bundle: .module
    )

    private let isHapticsEnabled: Bool
    private let onCompletion: () -> Void

    @Environment(\.accessibilityReduceMotion)
    private var accessibilityReduceMotion
    @State private var didComplete = false
    @State private var hapticsPlayer = SplashHapticsPlayer()

    public init(
        isHapticsEnabled: Bool,
        onCompletion: @escaping () -> Void
    ) {
        self.isHapticsEnabled = isHapticsEnabled
        self.onCompletion = onCompletion
    }

    public var body: some View {
        if accessibilityReduceMotion {
            completionPlaceholder
        } else if let animation = Self.animation {
            LottieView(animation: animation)
                .playing()
                .backgroundBehavior(.pauseAndRestore)
                .animationDidFinish { completed in
                    guard completed else {
                        return
                    }
                    complete()
                }
                .resizable()
                .aspectRatio(contentMode: .fit)
                .onAppear {
                    guard isHapticsEnabled else {
                        return
                    }

                    hapticsPlayer.play()
                }
        } else {
            completionPlaceholder
        }
    }

    private var completionPlaceholder: some View {
        Color.clear
            .onAppear {
                complete()
            }
    }

    private func complete() {
        guard !didComplete else {
            return
        }

        didComplete = true
        onCompletion()
    }
}
