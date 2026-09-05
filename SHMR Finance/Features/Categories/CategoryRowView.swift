//
//  CategoryRowView.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 19.07.2026.
//

import SwiftUI

private enum Constants {
    static let minimumHeight: CGFloat = 60
    static let iconWidth: CGFloat = 24
    static let spacing: CGFloat = 12
    static let iconFont = Font.title3
    static let titleFont = Font.body
}

struct CategoryRowView: View {
    let category: Category

    var body: some View {
        HStack(spacing: Constants.spacing) {
            Text(String(category.emoji))
                .font(Constants.iconFont)
                .frame(width: Constants.iconWidth)

            Text(category.name)
                .font(Constants.titleFont)

            Spacer(minLength: .zero)
        }
        .frame(minHeight: Constants.minimumHeight)
        .contentShape(Rectangle())
    }
}
