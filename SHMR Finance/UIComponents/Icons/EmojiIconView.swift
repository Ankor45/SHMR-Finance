//
//  EmojiIconView.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 19.07.2026.
//

import SwiftUI

private enum Constants {
    static let size: CGFloat = 40
    static let font = Font.title3
    static let backgroundColor = Color(.secondarySystemBackground)
}

struct EmojiIconView: View {
    // MARK: - Properties

    let emoji: String
    // MARK: - View Body

    var body: some View {
        Text(emoji)
            .font(Constants.font)
            .frame(width: Constants.size, height: Constants.size)
            .background(Constants.backgroundColor, in: Circle())
    }
}
