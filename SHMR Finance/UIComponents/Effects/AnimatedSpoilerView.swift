//
//  AnimatedSpoilerView.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 19.07.2026.
//

import SwiftUI

private struct SpoilerParticle {
    let baseX: Double
    let baseY: Double
    let speed: Double
    let wavePhase: Double
    let size: CGFloat
    let opacity: Double
}

private enum Constants {
    static let maximumParticleCount = 72
    static let minimumParticleCount = 16
    static let pointsPerParticle: CGFloat = 110
    static let minimumParticleSize: CGFloat = 1
    static let particleSizeRange: CGFloat = 2
    static let minimumOpacity = 0.35
    static let opacityRange = 0.5
    static let minimumSpeed = 0.025
    static let speedRange = 0.045
    static let verticalAmplitude = 0.08
    static let framesPerSecond = 30.0
    static let cornerRadius: CGFloat = 6
    static let backgroundOpacity = 0.22
    static let blurRadius: CGFloat = 0.35
    static let animation = Animation.easeInOut(duration: 0.2)
    static var hiddenAccessibilityLabel: String {
        AppLocalization.string(
            localized: "Баланс скрыт"
        )
    }
    static let seedMultiplier = 12.9898
    static let seedScale = 43_758.5453
    static let horizontalSalt = 17.17
    static let verticalSalt = 41.73
    static let sizeSalt = 73.31
    static let speedSalt = 97.13
    static let opacitySalt = 131.19
    static let waveSalt = 163.81
    static let fullCircle = Double.pi * 2

    static let particles: [SpoilerParticle] =
        (0..<maximumParticleCount).map { index in
            SpoilerParticle(
                baseX: randomValue(
                    index: index,
                    salt: horizontalSalt
                ),
                baseY: randomValue(
                    index: index,
                    salt: verticalSalt
                ),
                speed: minimumSpeed
                    + randomValue(
                        index: index,
                        salt: speedSalt
                    ) * speedRange,
                wavePhase: randomValue(
                    index: index,
                    salt: waveSalt
                ) * fullCircle,
                size: minimumParticleSize
                    + randomValue(
                        index: index,
                        salt: sizeSalt
                    ) * particleSizeRange,
                opacity: minimumOpacity
                    + randomValue(
                        index: index,
                        salt: opacitySalt
                    ) * opacityRange
            )
        }

    private static func randomValue(
        index: Int,
        salt: Double
    ) -> Double {
        let value = sin(
            Double(index) * seedMultiplier + salt
        ) * seedScale

        return value - floor(value)
    }
}

struct AnimatedSpoilerView<Content: View>: View {
    // MARK: - Properties

    @Environment(\.accessibilityReduceMotion)
    private var accessibilityReduceMotion
    @Environment(\.scenePhase) private var scenePhase

    let isHidden: Bool
    private let content: Content

    // MARK: - Initializers

    init(
        isHidden: Bool,
        @ViewBuilder content: () -> Content
    ) {
        self.isHidden = isHidden
        self.content = content()
    }

    // MARK: - View Body

    var body: some View {
        content
            .opacity(isHidden ? .zero : 1)
            .accessibilityHidden(isHidden)
            .overlay {
                if isHidden {
                    particleLayer
                        .transition(.opacity)
                        .accessibilityElement()
                        .accessibilityLabel(
                            Constants.hiddenAccessibilityLabel
                        )
                }
            }
            .animation(
                accessibilityReduceMotion
                    ? nil
                    : Constants.animation,
                value: isHidden
            )
    }

    // MARK: - Private Properties

    private var particleLayer: some View {
        TimelineView(
            .animation(
                minimumInterval: 1 / Constants.framesPerSecond,
                paused:
                    accessibilityReduceMotion
                    || scenePhase != .active
            )
        ) { timeline in
            Canvas(rendersAsynchronously: true) { context, size in
                drawBackground(in: &context, size: size)
                drawParticles(
                    in: &context,
                    size: size,
                    date: timeline.date
                )
            }
        }
        .clipShape(
            RoundedRectangle(cornerRadius: Constants.cornerRadius)
        )
        .blur(radius: Constants.blurRadius)
        .allowsHitTesting(false)
    }

    // MARK: - Private Methods

    private func drawBackground(
        in context: inout GraphicsContext,
        size: CGSize
    ) {
        let path = Path(
            roundedRect: CGRect(origin: .zero, size: size),
            cornerRadius: Constants.cornerRadius
        )
        context.fill(
            path,
            with: .color(
                Color.secondary.opacity(Constants.backgroundOpacity)
            )
        )
    }

    private func drawParticles(
        in context: inout GraphicsContext,
        size: CGSize,
        date: Date
    ) {
        let time = date.timeIntervalSinceReferenceDate
        let particleCount = min(
            Constants.maximumParticleCount,
            max(
                Constants.minimumParticleCount,
                Int(
                    size.width * size.height
                        / Constants.pointsPerParticle
                )
            )
        )

        for particle in Constants.particles.prefix(particleCount) {
            let normalizedX = wrapped(
                particle.baseX + time * particle.speed
            )
            let normalizedY = wrapped(
                particle.baseY
                    + sin(
                        time * particle.speed * Constants.fullCircle
                            + particle.wavePhase
                    )
                    * Constants.verticalAmplitude
            )
            let particleRect = CGRect(
                x: normalizedX * size.width - particle.size / 2,
                y: normalizedY * size.height - particle.size / 2,
                width: particle.size,
                height: particle.size
            )

            context.fill(
                Path(ellipseIn: particleRect),
                with: .color(
                    Color.secondary.opacity(particle.opacity)
                )
            )
        }
    }

    private func wrapped(_ value: Double) -> Double {
        value - floor(value)
    }
}
