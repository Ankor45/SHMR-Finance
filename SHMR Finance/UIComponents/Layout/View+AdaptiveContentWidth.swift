//
//  View+AdaptiveContentWidth.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 06.08.2026.
//

import SwiftUI

private enum Constants {
    static let maximumContentWidth: CGFloat = 760
}

extension View {
    func adaptiveContentWidth() -> some View {
        frame(maxWidth: Constants.maximumContentWidth)
            .frame(maxWidth: .infinity)
    }
}
