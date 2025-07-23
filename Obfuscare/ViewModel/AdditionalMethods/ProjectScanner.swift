//
//  ProjectScanner.swift
//  Obfuscare
//
//  Created by Macintosh HD on 22.07.2025.
//

import Foundation

class ProjectScanner {
    func scan(forSwiftFilesIn rootURL: URL) -> [URL] {
        var swiftFiles: [URL] = []

        if let enumerator = FileManager.default.enumerator(at: rootURL, includingPropertiesForKeys: nil) {
            for case let fileURL as URL in enumerator {
                if fileURL.pathExtension == "swift" {
                    swiftFiles.append(fileURL)
                }
            }
        }

        return swiftFiles
    }
}
