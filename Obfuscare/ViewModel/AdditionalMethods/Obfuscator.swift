//
//  Obfuscator.swift
//  Obfuscare
//
//  Created by Macintosh HD on 15.07.2025.
//

import Foundation

class Obfuscator {
    var obfuscationMap: [String: [String: String]] = [:] // typeName -> [original: obfuscated]
    private let englishWords = [
        "Exp23_07_01","Exp23_07_02","Exp23_07_03","Exp23_07_04","Exp23_07_05","Exp23_07_06","Exp23_07_07","Exp23_07_08","Exp23_07_09","Exp23_07_010",
        "Exp23_07_011","Exp23_07_012","Exp23_07_013","Exp23_07_014","Exp23_07_015","Exp23_07_016","Exp23_07_017","Exp23_07_018","Exp23_07_019","Exp23_07_020","Exp23_07_021","Exp23_07_022","Exp23_07_023","Exp23_07_024","Exp23_07_025","Exp23_07_026","Exp23_07_027","Exp23_07_028","Exp23_07_029","Exp23_07_030","Exp23_07_031","Exp23_07_032","Exp23_07_033","Exp23_07_034","Exp23_07_035","Exp23_07_036","Exp23_07_037","Exp23_07_038","Exp23_07_039","Exp23_07_040","Exp23_07_041",
    ]
    
    
    
//    let englishWords = ["Apple", "Orange", "Cloud", "Rocket", "Dream", "Falcon", "Tiger", "Echo"]

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

    /*
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
     */
    
    func obfuscateVariables(in fileURL: URL, instanceToType: [String: String]) {
        guard var content = try? String(contentsOf: fileURL) else { return }

        for (typeName, mapping) in obfuscationMap {
            for (original, obfuscated) in mapping {
                // Базові патерни: self.property і просто property
                let basePatterns: [(pattern: String, template: String)] = [
                    ("\\bself\\.\(original)\\b", "self.\(obfuscated)"),
                    ("(?<!\\w)\(original)\\b", obfuscated)
                ]

                // Вкладені виклики через екземпляри об'єктів
                let nestedPatterns: [(pattern: String, template: String)] = instanceToType
                    .filter { $0.value == typeName }
                    .flatMap { instance, _ in
                        return [
                            ("\\bself\\.\(instance)\\.\(original)\\b", "self.\(instance).\(obfuscated)"),
                            ("(?<!\\w)\(instance)\\.\(original)\\b", "\(instance).\(obfuscated)")
                        ]
                    }

                // Об’єднуємо всі патерни
                let allPatterns = basePatterns + nestedPatterns

                // Застосовуємо обфускацію
                for (pattern, template) in allPatterns {
                    if let regex = try? NSRegularExpression(pattern: pattern) {
                        let range = NSRange(content.startIndex..<content.endIndex, in: content)
                        content = regex.stringByReplacingMatches(in: content, options: [], range: range, withTemplate: template)
                    }
                }
            }
        }

        try? content.write(to: fileURL, atomically: true, encoding: .utf8)
    }


}

/*
class Obfuscator {
    var obfuscatedVariablesByType: [String: [String: String]] = [:]
    
    private let englishWords = [
        "Experiment1", "Experiment2", "Experiment3", "Experiment4", "Experiment5", "Experiment6",
        "Experiment7", "Experiment8", "Experiment9", "Experiment10", "Experiment11", "Experiment12",
        "Experiment13", "Experiment14", "Experiment156", "Experiment17", "Experiment18", "Experiment19"
    ]

    
    func generateObfuscationMap(from variables: [VariableInfo]) {
        let grouped = Dictionary(grouping: variables, by: { $0.typeName })

        for (typeName, vars) in grouped {
            var usedSuffixes = Set<String>()
            var propertyMap: [String: String] = [:]

            for variable in vars {
                let firstWord = extractFirstWord(from: variable.variableName)
                var suffix: String
                repeat {
                    suffix = englishWords.randomElement() ?? UUID().uuidString
                } while usedSuffixes.contains(suffix)
                usedSuffixes.insert(suffix)
                
                propertyMap[variable.variableName] = firstWord + suffix
            }

            obfuscatedVariablesByType[typeName] = propertyMap
        }
    }

    func extractFirstWord(from camelCase: String) -> String {
        let pattern = #"^[a-z]+"#
        return camelCase.firstMatch(of: pattern)?
            .dropFirst()
            .first
            .map { String($0) } ?? camelCase
    }

    func obfuscatePropertyAccess(in fileURL: URL, instanceToType: [String: String]) {
        guard var content = try? String(contentsOf: fileURL) else { return }

        for (typeName, props) in obfuscatedVariablesByType {
            for (original, obfuscated) in props {
                let pattern = #"(?<![\w\d])\#(typeName)\.\#(original)\b"#
                let regex = try! NSRegularExpression(pattern: pattern)
                content = regex.stringByReplacingMatches(
                    in: content,
                    options: [],
                    range: NSRange(content.startIndex..., in: content),
                    withTemplate: "\(typeName).\(obfuscated)"
                )
            }
        }

        for (instanceName, typeName) in instanceToType {
            guard let props = obfuscatedVariablesByType[typeName] else { continue }
            for (original, obfuscated) in props {
                let pattern = #"(?<![\w\d])\#(instanceName)\.\#(original)\b"#
                let regex = try! NSRegularExpression(pattern: pattern)
                content = regex.stringByReplacingMatches(
                    in: content,
                    options: [],
                    range: NSRange(content.startIndex..., in: content),
                    withTemplate: "\(instanceName).\(obfuscated)"
                )
            }
        }

        // self.instance.property
        for (instanceName, typeName) in instanceToType {
            guard let props = obfuscatedVariablesByType[typeName] else { continue }
            for (original, obfuscated) in props {
                let pattern = #"(?<![\w\d])self\.\#(instanceName)\.\#(original)\b"#
                let regex = try! NSRegularExpression(pattern: pattern)
                content = regex.stringByReplacingMatches(
                    in: content,
                    options: [],
                    range: NSRange(content.startIndex..., in: content),
                    withTemplate: "self.\(instanceName).\(obfuscated)"
                )
            }
        }

        // Записати назад
        try? content.write(to: fileURL, atomically: true, encoding: .utf8)
    }
}

*/
/*
class Obfuscator {
    private let englishWords = [
        "Experiment1", "Experiment2", "Experiment3", "Experiment4", "Experiment5", "Experiment6",
        "Experiment7", "Experiment8", "Experiment9", "Experiment10", "Experiment11", "Experiment12",
        "Experiment13", "Experiment14", "Experiment156", "Experiment17", "Experiment18", "Experiment19"
    ]

    func obfuscate(variables: [Variable]) {
        let grouped = Dictionary(grouping: variables, by: { $0.filePath })

        for (filePath, variablesInFile) in grouped {
            do {
                let originalContent = try String(contentsOfFile: filePath)
                var modifiedContent = originalContent

                var usedSuffixes: Set<String> = []
                var obfuscationMap: [String: String] = [:]

                // Генеруємо обфусковані імена для кожної змінної
                for variable in variablesInFile {
                    let firstWord = getFirstWord(from: variable.name)

                    // Генеруємо унікальний суфікс для firstWord
                    var suffix: String
                    repeat {
                        suffix = englishWords.randomElement() ?? UUID().uuidString
                    } while usedSuffixes.contains(suffix)

                    usedSuffixes.insert(suffix)
                    let newName = "\(firstWord)\(suffix)"
                    obfuscationMap[variable.name] = newName
                }

                // Замінюємо входження змінних у файлі
                for (oldName, newName) in obfuscationMap.sorted(by: { $0.key.count > $1.key.count }) {
                    modifiedContent = replaceVariableName(in: modifiedContent, oldName: oldName, newName: newName)
                }

                try modifiedContent.write(toFile: filePath, atomically: true, encoding: .utf8)
                print("✅ Файл обфусковано: \(filePath)")
            } catch {
                print("❌ Помилка роботи з файлом \(filePath): \(error)")
            }
        }
    }
    
    
    func obfuscatePropertyAccess(
        in folderPath: String,
        obfuscatedVariablesByType: [String: [String: String]]
    ) {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(at: URL(fileURLWithPath: folderPath), includingPropertiesForKeys: nil) else {
            print("❌ Failed to create enumerator")
            return
        }

        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension == "swift" else { continue }
            guard var content = try? String(contentsOf: fileURL) else { continue }

            var instanceToType: [String: String] = [:]

            // 🔹 1. Варіант: var name = Type(...)
            let initPattern = #"(?:let|var)\s+(\w+)\s*(?::\s*\w+\??)?\s*=\s*(\w+)\s*\([^)]*\)"#
            let initRegex = try! NSRegularExpression(pattern: initPattern)
            for match in initRegex.matches(in: content, range: NSRange(content.startIndex..., in: content)) {
                let name = (content as NSString).substring(with: match.range(at: 1))
                let type = (content as NSString).substring(with: match.range(at: 2))
                instanceToType[name] = type
            }

            // 🔹 2. Варіант: var name: Type? або var name: Type
            let typedPattern = #"(?:let|var)\s+(\w+)\s*:\s*(\w+)\??"#
            let typedRegex = try! NSRegularExpression(pattern: typedPattern)
            for match in typedRegex.matches(in: content, range: NSRange(content.startIndex..., in: content)) {
                let name = (content as NSString).substring(with: match.range(at: 1))
                let type = (content as NSString).substring(with: match.range(at: 2))
                if instanceToType[name] == nil {
                    instanceToType[name] = type
                }
            }

            // 🔁 Обфускація доступів типу instance.property
            for (instanceName, typeName) in instanceToType {
                guard let propertyMap = obfuscatedVariablesByType[typeName] else { continue }

                for (originalName, obfuscatedName) in propertyMap {
                    let pattern = #"(?<![\w\d])\#(instanceName)\.\#(originalName)\b"#
                    let propertyRegex = try! NSRegularExpression(pattern: pattern)
                    content = propertyRegex.stringByReplacingMatches(
                        in: content,
                        options: [],
                        range: NSRange(content.startIndex..., in: content),
                        withTemplate: "\(instanceName).\(obfuscatedName)"
                    )
                }
            }

            // 🔁 Обфускація статичних властивостей: TypeName.propertyName
            for (typeName, propertyMap) in obfuscatedVariablesByType {
                for (originalName, obfuscatedName) in propertyMap {
                    let pattern = #"(?<![\w\d])\#(typeName)\.\#(originalName)\b"#
                    let staticRegex = try! NSRegularExpression(pattern: pattern)
                    content = staticRegex.stringByReplacingMatches(
                        in: content,
                        options: [],
                        range: NSRange(content.startIndex..., in: content),
                        withTemplate: "\(typeName).\(obfuscatedName)"
                    )
                }
            }

            // 🔁 Обфускація self.propertyName
            for (_, propertyMap) in obfuscatedVariablesByType {
                for (originalName, obfuscatedName) in propertyMap {
                    let pattern = #"(?<![\w\d])self\.\#(originalName)\b"#
                    let selfRegex = try! NSRegularExpression(pattern: pattern)
                    content = selfRegex.stringByReplacingMatches(
                        in: content,
                        options: [],
                        range: NSRange(content.startIndex..., in: content),
                        withTemplate: "self.\(obfuscatedName)"
                    )
                }
            }

            // 💾 Перезапис файлу
            try? content.write(to: fileURL, atomically: true, encoding: .utf8)
        }
    }


    private func getFirstWord(from name: String) -> String {
        return String(name.prefix { $0.isLowercase })
    }

    private func replaceVariableName(in content: String, oldName: String, newName: String) -> String {
        let pattern = #"(?<!\w)(\b\#(oldName))(?=\b|(?=\.))"#
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: (content as NSString).length)

        return regex.stringByReplacingMatches(
            in: content,
            options: [],
            range: range,
            withTemplate: newName
        )
    }
}

*/
