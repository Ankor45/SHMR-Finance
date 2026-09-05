//
//  LiquidGlassTabBar.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 18.07.2026.
//

import SwiftUI

private enum Constants {
    enum Selection {
        static let namespaceId = "selectedTab"
        static let fillOpacity = 0.06
        static let borderOpacity = 0.16
        static let shadowOpacity = 0.1
        static let shadowRadius: CGFloat = 6
        static let shadowYOffset: CGFloat = 2
    }

    enum Item {
        static let spacing: CGFloat = 1
        static let iconFont = Font.system(size: 18, weight: .medium)
        static let titleFont = Font.caption2.weight(.semibold)
        static let titleLineLimit = 1
    }

    static let contentPadding: CGFloat = 4
    static let backgroundOpacity = 0.04
    static let borderOpacity = 0.18
    static let borderWidth: CGFloat = 0.5
    static let shadowOpacity = 0.16
    static let shadowRadius: CGFloat = 16
    static let shadowYOffset: CGFloat = 8
}

struct LiquidGlassTabBar: View {
    // MARK: - Properties

    @Environment(HapticsService.self) private var hapticsService
    @Binding var selection: AppTab
    @Namespace private var selectionNamespace
    
    // MARK: - View Body
    var body: some View {
        HStack(spacing: .zero) {
            ForEach(AppTab.allCases) { tab in
                tabButton(for: tab)
            }
        }
        .padding(Constants.contentPadding)
        .frame(maxWidth: AppTabBarMetrics.maximumWidth)
        .frame(height: AppTabBarMetrics.height)
        .background(.ultraThinMaterial, in: Capsule())
        .background {
            Capsule()
                .fill(Color.primary.opacity(Constants.backgroundOpacity))
        }
        .overlay {
            Capsule()
                .strokeBorder(
                    Color.white.opacity(Constants.borderOpacity),
                    lineWidth: Constants.borderWidth
                )
        }
        .shadow(
            color: .black.opacity(Constants.shadowOpacity),
            radius: Constants.shadowRadius,
            y: Constants.shadowYOffset
        )
        .accessibilityElement(children: .contain)
    }

    // MARK: - Private Properties

    private func tabButton(for tab: AppTab) -> some View {
        let isSelected = selection == tab

        return Button {
            guard selection != tab else {
                return
            }

            hapticsService.selectionChanged()
            selection = tab
        } label: {
            VStack(spacing: Constants.Item.spacing) {
                Image(systemName: tab.iconName)
                    .font(Constants.Item.iconFont)
                
                Text(tab.title)
                    .font(Constants.Item.titleFont)
                    .lineLimit(Constants.Item.titleLineLimit)
            }
            .foregroundStyle(
                isSelected
                    ? AnyShapeStyle(.tint)
                    : AnyShapeStyle(.primary)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                if isSelected {
                    Capsule()
                        .fill(.thinMaterial)
                        .overlay {
                            Capsule()
                                .fill(
                                    Color.primary.opacity(
                                        Constants.Selection.fillOpacity
                                    )
                                )
                        }
                        .overlay {
                            Capsule()
                                .strokeBorder(
                                    Color.white.opacity(
                                        Constants.Selection.borderOpacity
                                    ),
                                    lineWidth: Constants.borderWidth
                                )
                        }
                        .matchedGeometryEffect(
                            id: Constants.Selection.namespaceId,
                            in: selectionNamespace
                        )
                        .shadow(
                            color: .black.opacity(
                                Constants.Selection.shadowOpacity
                            ),
                            radius: Constants.Selection.shadowRadius,
                            y: Constants.Selection.shadowYOffset
                        )
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
