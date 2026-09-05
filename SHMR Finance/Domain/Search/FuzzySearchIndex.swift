//
//  FuzzySearchIndex.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 19.07.2026.
//

struct FuzzySearchIndex<Element> {
    // MARK: - Private Types

    private struct Entry {
        let element: Element
        let sourceIndex: Int
        let text: NormalizedSearchText
    }

    private struct Match {
        let element: Element
        let sourceIndex: Int
        let score: Int
    }

    // MARK: - Properties

    private let entries: [Entry]

    // MARK: - Initializers

    init() {
        entries = []
    }

    init(
        _ elements: [Element],
        searchableText: (Element) -> String
    ) {
        entries = elements.enumerated().map { index, element in
            Entry(
                element: element,
                sourceIndex: index,
                text: NormalizedSearchText(searchableText(element))
            )
        }
    }

    // MARK: - Methods

    func search(query: String) -> [Element] {
        let normalizedQuery = NormalizedSearchText(query).characters

        guard !normalizedQuery.isEmpty else {
            return entries.map(\.element)
        }

        return entries
            .compactMap { entry -> Match? in
                guard let score = FuzzyMatcher.score(
                    query: normalizedQuery,
                    candidate: entry.text
                ) else {
                    return nil
                }

                return Match(
                    element: entry.element,
                    sourceIndex: entry.sourceIndex,
                    score: score
                )
            }
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    return lhs.sourceIndex < rhs.sourceIndex
                }

                return lhs.score > rhs.score
            }
            .map(\.element)
    }
}
