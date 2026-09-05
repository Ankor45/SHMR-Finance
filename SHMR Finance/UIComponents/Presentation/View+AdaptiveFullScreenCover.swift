//
//  View+AdaptiveFullScreenCover.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 06.08.2026.
//

import SwiftUI
import UIKit

extension View {
    @ViewBuilder
    func adaptiveFullScreenCover<Content: View>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            sheet(
                isPresented: isPresented,
                onDismiss: onDismiss,
                content: content
            )
        } else {
            fullScreenCover(
                isPresented: isPresented,
                onDismiss: onDismiss,
                content: content
            )
        }
    }

    @ViewBuilder
    func adaptiveFullScreenCover<
        Item: Identifiable,
        Content: View
    >(
        item: Binding<Item?>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            sheet(
                item: item,
                onDismiss: onDismiss,
                content: content
            )
        } else {
            fullScreenCover(
                item: item,
                onDismiss: onDismiss,
                content: content
            )
        }
    }
}
