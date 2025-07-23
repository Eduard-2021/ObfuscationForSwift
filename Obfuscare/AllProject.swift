//
//  AllProject.swift
//  Obfuscare
//
//  Created by Macintosh HD on 21.07.2025.
//

// main.swift
/*
import Foundation

// MARK: - VariableInfo
/*
struct VariableInfo {
    let filePath: String
    let typeName: String
    let variableName: String
}
*/
// MARK: - InstanceInfo
/*
struct InstanceInfo {
    let filePath: String
    let instanceName: String
    let typeName: String
}
*/
// MARK: - ProjectScanner
/*
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
*/
// MARK: - CamelCaseDetector
/*
class CamelCaseDetector {
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

                if name.first?.isLowercase == true && name.contains(where: { $0.isUppercase }) {
                    result.append(VariableInfo(filePath: fileURL.path, typeName: typeName, variableName: name))
                }
            }
        }

        return result
    }
}
*/
// MARK: - InstanceDetector
/*
class InstanceDetector {
    func detectInstances(in fileURL: URL) -> [InstanceInfo] {
        guard let content = try? String(contentsOf: fileURL) else { return [] }
        let pattern = "\\b(var|let)\\s+(\\w+)\\s*:?\\s*(\\w+)\\??\\s*(=\\s*\\w+\\([^)]*\\))?"
        let regex = try! NSRegularExpression(pattern: pattern, options: [])

        var results: [InstanceInfo] = []
        let nsrange = NSRange(content.startIndex..<content.endIndex, in: content)

        regex.enumerateMatches(in: content, options: [], range: nsrange) { match, _, _ in
            guard
                let match = match,
                let instanceRange = Range(match.range(at: 2), in: content),
                let typeRange = Range(match.range(at: 3), in: content)
            else { return }

            let instance = String(content[instanceRange])
            let type = String(content[typeRange])

            results.append(InstanceInfo(filePath: fileURL.path, instanceName: instance, typeName: type))
        }

        return results
    }
}
*/
// MARK: - Obfuscator
/*
class Obfuscator {
    var obfuscationMap: [String: [String: String]] = [:] // typeName -> [original: obfuscated]
    let englishWords = ["Apple", "Orange", "Cloud", "Rocket", "Dream", "Falcon", "Tiger", "Echo"]

    func generateObfuscationMap(from variables: [VariableInfo]) {
        let grouped = Dictionary(grouping: variables, by: { $0.typeName })

        for (type, vars) in grouped {
            var usedSuffixes = Set<String>()
            var nameMap: [String: String] = [:]

            for variable in vars {
                let firstWord = extractFirstWord(from: variable.variableName)
                var suffix: String

                repeat {
                    suffix = englishWords.randomElement() ?? UUID().uuidString
                } while usedSuffixes.contains(suffix)

                usedSuffixes.insert(suffix)
                nameMap[variable.variableName] = firstWord + suffix
            }

            obfuscationMap[type] = nameMap
        }
    }

    private func extractFirstWord(from camelCase: String) -> String {
        let pattern = "^[a-z]+"
        if let range = camelCase.range(of: pattern, options: .regularExpression) {
            return String(camelCase[range])
        }
        return camelCase
    }

    func obfuscateVariables(in fileURL: URL, instanceToType: [String: String]) {
        guard var content = try? String(contentsOf: fileURL) else { return }

        for (typeName, mapping) in obfuscationMap {
            for (original, obfuscated) in mapping {
                let patterns = [
                    "\\bself\\.\(original)\\b",
                    "\\b\(original)\\b",
                ] + instanceToType.compactMap { instance, type in
                    type == typeName ? "\\bself?\\.\(instance)\\.\(original)\\b" : nil
                }

                for pattern in patterns {
                    let regex = try! NSRegularExpression(pattern: pattern)
                    let range = NSRange(content.startIndex..<content.endIndex, in: content)
                    content = regex.stringByReplacingMatches(in: content, options: [], range: range, withTemplate: obfuscated)
                }
            }
        }

        try? content.write(to: fileURL, atomically: true, encoding: .utf8)
    }
}
*/
// MARK: - ObfuscationRunner

class ObfuscationRunner {
    let projectScanner = ProjectScanner()
    let detector = CamelCaseDetector()
    let instanceDetector = InstanceDetector()
    let obfuscator = Obfuscator()

    func runObfuscation(on rootURL: URL) {
        let swiftFiles = projectScanner.scan(forSwiftFilesIn: rootURL)

        let allVariables = swiftFiles.flatMap { detector.detectVariables(in: $0) }
        obfuscator.generateObfuscationMap(from: allVariables)

        var instancesPerFile: [String: [String: String]] = [:]
        for file in swiftFiles {
            let instances = instanceDetector.detectInstances(in: file)
            instancesPerFile[file.path] = Dictionary(uniqueKeysWithValues: instances.map { ($0.instanceName, $0.typeName) })
        }

        for file in swiftFiles {
            let instanceMap = instancesPerFile[file.path] ?? [:]
            obfuscator.obfuscateVariables(in: file, instanceToType: instanceMap)
        }
    }
}

// MARK: - Запуск
/*
let rootPath = "/Users/macintoshhd/Documents/Xcode/Work/Test/TestObfuscare1"
let rootURL = URL(fileURLWithPath: rootPath)
ObfuscationRunner().runObfuscation(on: rootURL)
*/

*/
