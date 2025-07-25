//
//  CamelCaseDetector.swift
//  Obfuscare
//
//  Created by Macintosh HD on 15.07.2025.
//

import Foundation

class CamelCaseDetector {
    /*
    func detectVariables(in fileURL: URL) -> [VariableInfo] {
        guard let content = try? String(contentsOf: fileURL) else { return [] }

        let typeRegex = try! NSRegularExpression(pattern: "(class|struct)\\s+(\\w+)", options: [])
        let variableRegex = try! NSRegularExpression(pattern: "\\b(let|var)\\s+(\\w+)", options: [])

        var result: [VariableInfo] = []
        let nsrange = NSRange(content.startIndex..<content.endIndex, in: content)

        let typeMatches = typeRegex.matches(in: content, options: [], range: nsrange)

        for match in typeMatches {
            guard let typeRange = Range(match.range(at: 2), in: content) else { continue }
            let typeName = String(content[typeRange])

            let bodyStart = match.range(at: 2).upperBound
            let bodyEnd = content.range(of: "\n}" , options: [], range: Range(NSRange(location: bodyStart, length: nsrange.length - bodyStart), in: content))?.lowerBound ?? content.endIndex

            let bodyRange = NSRange(content.index(content.startIndex, offsetBy: bodyStart)..<bodyEnd, in: content)

            let variableMatches = variableRegex.matches(in: content, options: [], range: bodyRange)
            for varMatch in variableMatches {
                guard let nameRange = Range(varMatch.range(at: 2), in: content) else { continue }
                let name = String(content[nameRange])

                if name.first?.isLowercase == true && name != "body" /*&& name.contains(where: { $0.isUppercase })*/ {
                    result.append(VariableInfo(filePath: fileURL.path, typeName: typeName, variableName: name))
                }
            }
        }

        return result
    }
    */
    
    func detectVariablesAndMethods(in fileURL: URL) -> [VariableInfo] {
        guard let content = try? String(contentsOf: fileURL) else { return [] }

        let typeRegex = try! NSRegularExpression(pattern: "(class|struct)\\s+(\\w+)", options: [])
        let variableRegex = try! NSRegularExpression(
            pattern: #"(?<!case\s)\b(let|var)\s+(\w+)"#,
            options: []
        )
        let methodRegex = try! NSRegularExpression(
            pattern: #"(?:\b\w+\s+)*func\s+(\w+)"#, 
            options: []
        )

        var result: [VariableInfo] = []
        let nsrange = NSRange(content.startIndex..<content.endIndex, in: content)
        let typeMatches = typeRegex.matches(in: content, options: [], range: nsrange)

        for match in typeMatches {
            guard let typeRange = Range(match.range(at: 2), in: content) else { continue }
            let typeName = String(content[typeRange])

            let bodyStart = match.range(at: 2).upperBound
            let remainingLength = nsrange.length - bodyStart
            guard remainingLength > 0 else { continue }

            let bodySearchRange = NSRange(location: bodyStart, length: remainingLength)
            let closingBrace = content.range(of: "\n}", options: [], range: Range(bodySearchRange, in: content))?.lowerBound ?? content.endIndex
            let bodyRange = NSRange(content.index(content.startIndex, offsetBy: bodyStart)..<closingBrace, in: content)

            // Змінні
            let variableMatches = variableRegex.matches(in: content, options: [], range: bodyRange)
            for varMatch in variableMatches {
                guard let nameRange = Range(varMatch.range(at: 2), in: content) else { continue }
                let name = String(content[nameRange])
                if name.first?.isLowercase == true && name != "body" {
                    result.append(VariableInfo(filePath: fileURL.path, typeName: typeName, variableName: name, isMethod: false))
                }
            }

            // Методи
            let methodMatches = methodRegex.matches(in: content, options: [], range: bodyRange)
            for methodMatch in methodMatches {
                guard let nameRange = Range(methodMatch.range(at: 1), in: content) else { continue }
                let name = String(content[nameRange])
                if name.first?.isLowercase == true && name != "body" {
                    result.append(VariableInfo(filePath: fileURL.path, typeName: typeName, variableName: name, isMethod: true))
                }
            }
        }

        return result
    }

    
    
    
    
}





/*
class CamelCaseDetector {
    
    func detectVariables(in fileURL: URL) -> [VariableInfo] {
        guard let content = try? String(contentsOf: fileURL) else { return [] }

        var results: [VariableInfo] = []

        let lines = content.components(separatedBy: .newlines)
        var currentTypeName: String? = nil

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // 🔍 Detect struct or class
            if let match = trimmed.firstMatch(of: #"^(class|struct)\s+(\w+)"#) {
                currentTypeName = match[2]
                continue
            }

            guard let typeName = currentTypeName else { continue }

            // 🔍 Detect camelCase let/var
            if let match = trimmed.firstMatch(of: #"^(?:static\s+)?(?:let|var)\s+([a-z][a-zA-Z0-9]*)\b"#) {
                let variableName = match[1]
                results.append(VariableInfo(
                    filePath: fileURL.path,
                    typeName: typeName,
                    variableName: variableName
                ))
            }
        }

        return results
    }
}
*/

/*
class CamelCaseDetector {
    private let fileManager = FileManager.default
    private let rootURL: URL
    private let regex = try! NSRegularExpression(pattern: #"(?<![\w])(?:let|var)\s+([a-z][a-zA-Z0-9]*)"#)

    init(projectPath: String) {
        self.rootURL = URL(fileURLWithPath: projectPath)
    }

    func scanProject() -> [Variable] {
        var results: [Variable] = []

        /*
        guard let enumerator = fileManager.enumerator(at: rootURL, includingPropertiesForKeys: nil) else {
            return []
        }
         */
        
        guard FileManager.default.fileExists(atPath: rootURL.path) else {
            print("Директорія не існує: \(rootURL.path)")
            return []
        }
        
        guard let enumerator = fileManager.enumerator(
            at: rootURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension == "swift" else { continue }

            do {
                let content = try String(contentsOf: fileURL)
                let nsContent = content as NSString
                let matches = regex.matches(in: content, range: NSRange(location: 0, length: nsContent.length))

                for match in matches {
                    guard match.numberOfRanges > 1 else { continue }
                    let variableRange = match.range(at: 1)
                    let variableName = nsContent.substring(with: variableRange)
                    if isCamelCase(variableName) {
                        results.append(Variable(name: variableName, filePath: fileURL.path, range: variableRange))
                    }
                }
            } catch {
                print("Помилка читання \(fileURL.path): \(error)")
            }
        }

        return results
    }
    

    private func isCamelCase(_ name: String) -> Bool {
        let pattern = #"^[a-z]+(?:[A-Z][a-z0-9]*)+$"#
        return name.range(of: pattern, options: .regularExpression) != nil
    }
}
*/
