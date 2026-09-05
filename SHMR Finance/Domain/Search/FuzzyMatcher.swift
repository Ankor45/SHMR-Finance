//
//  FuzzyMatcher.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 19.07.2026.
//

private enum Constants {
    enum Score {
        static let exact = 10_000
        static let prefix = 8_000
        static let substring = 6_000
        static let subsequence = 4_000
        static let editDistance = 2_000
        static let consecutiveMultiplier = 12
        static let wordStartBonus = 24
        static let distancePenalty = 200
    }
}

enum FuzzyMatcher {
    static func score(
        query: [Character],
        candidate: NormalizedSearchText
    ) -> Int? {
        let candidateCharacters = candidate.characters

        guard !candidateCharacters.isEmpty else {
            return nil
        }

        if query == candidateCharacters {
            return Constants.Score.exact
        }

        if candidateCharacters.starts(with: query) {
            return Constants.Score.prefix
                - (candidateCharacters.count - query.count)
        }

        if let start = contiguousMatchStart(
            query: query,
            candidate: candidateCharacters
        ) {
            return Constants.Score.substring
                - start
                - (candidateCharacters.count - query.count)
        }

        if let score = subsequenceScore(
            query: query,
            candidate: candidateCharacters
        ) {
            return Constants.Score.subsequence + score
        }

        return editDistanceScore(
            query: query,
            candidate: candidate
        )
    }

    private static func contiguousMatchStart(
        query: [Character],
        candidate: [Character]
    ) -> Int? {
        guard query.count <= candidate.count else {
            return nil
        }

        for start in 0...(candidate.count - query.count) {
            let end = start + query.count

            if candidate[start..<end].elementsEqual(query) {
                return start
            }
        }

        return nil
    }

    private static func subsequenceScore(
        query: [Character],
        candidate: [Character]
    ) -> Int? {
        var queryIndex = 0
        var consecutiveMatches = 0
        var firstMatchIndex: Int?
        var lastMatchIndex: Int?
        var score = 0

        for (candidateIndex, character) in candidate.enumerated() {
            guard character == query[queryIndex] else {
                consecutiveMatches = 0
                continue
            }

            firstMatchIndex = firstMatchIndex ?? candidateIndex
            lastMatchIndex = candidateIndex
            queryIndex += 1
            consecutiveMatches += 1
            score += consecutiveMatches
                * Constants.Score.consecutiveMultiplier

            if candidateIndex == 0
                || candidate[candidateIndex - 1].isWhitespace {
                score += Constants.Score.wordStartBonus
            }

            if queryIndex == query.count {
                guard
                    let firstMatchIndex,
                    let lastMatchIndex
                else {
                    return nil
                }

                let gaps = lastMatchIndex
                    - firstMatchIndex
                    + 1
                    - query.count

                return score - firstMatchIndex - gaps
            }
        }

        return nil
    }

    private static func editDistanceScore(
        query: [Character],
        candidate: NormalizedSearchText
    ) -> Int? {
        let allowedDistance = maximumEditDistance(
            for: query.count
        )

        guard allowedDistance > 0 else {
            return nil
        }

        let comparisonTargets = candidate.words.count == 1
            ? [candidate.characters]
            : [candidate.characters] + candidate.words
        let distance = comparisonTargets
            .filter {
                abs($0.count - query.count) <= allowedDistance
            }
            .map {
                damerauLevenshteinDistance(
                    query,
                    $0,
                    limit: allowedDistance
                )
            }
            .min()

        guard let distance, distance <= allowedDistance else {
            return nil
        }

        return Constants.Score.editDistance
            - distance * Constants.Score.distancePenalty
    }

    private static func maximumEditDistance(
        for queryLength: Int
    ) -> Int {
        switch queryLength {
        case ...2:
            0
        case 3...5:
            1
        case 6...9:
            2
        default:
            3
        }
    }

    private static func damerauLevenshteinDistance(
        _ lhs: [Character],
        _ rhs: [Character],
        limit: Int
    ) -> Int {
        var previousPrevious = Array(0...rhs.count)
        var previous = previousPrevious

        for lhsIndex in 1...lhs.count {
            var current = Array(repeating: 0, count: rhs.count + 1)
            current[0] = lhsIndex
            var rowMinimum = current[0]

            for rhsIndex in 1...rhs.count {
                let substitutionCost = lhs[lhsIndex - 1]
                    == rhs[rhsIndex - 1] ? 0 : 1

                current[rhsIndex] = min(
                    previous[rhsIndex] + 1,
                    current[rhsIndex - 1] + 1,
                    previous[rhsIndex - 1] + substitutionCost
                )

                if lhsIndex > 1,
                   rhsIndex > 1,
                   lhs[lhsIndex - 1] == rhs[rhsIndex - 2],
                   lhs[lhsIndex - 2] == rhs[rhsIndex - 1] {
                    current[rhsIndex] = min(
                        current[rhsIndex],
                        previousPrevious[rhsIndex - 2] + 1
                    )
                }

                rowMinimum = min(rowMinimum, current[rhsIndex])
            }

            if rowMinimum > limit {
                return limit + 1
            }

            previousPrevious = previous
            previous = current
        }

        return previous[rhs.count]
    }
}
