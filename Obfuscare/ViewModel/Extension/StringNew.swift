//
//  StringNew.swift
//  Obfuscare
//
//  Created by Macintosh HD on 21.07.2025.
//

import Foundation

extension String {
    func firstMatch(of pattern: String) -> [String]? {
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(self.startIndex..., in: self)
        guard let match = regex?.firstMatch(in: self, range: range) else { return nil }

        return (0..<match.numberOfRanges).map {
            let range = match.range(at: $0)
            guard let swiftRange = Range(range, in: self) else { return "" }
            return String(self[swiftRange])
        }
    }
}
