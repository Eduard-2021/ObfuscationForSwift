//
//  Obfuscator.swift
//  Obfuscare
//
//  Created by Macintosh HD on 15.07.2025.
//

import Foundation

class Obfuscator {
    var variableObfuscationMap: [String: [String: String]] = [:] // typeName -> [original: obfuscated]
    var methodObfuscationMap: [String: [String: String]] = [:]
    
    private let englishWords = variableNames
    private var englishWordsSet = Set<String>()


//    let englishWords = ["Apple", "Orange", "Cloud", "Rocket", "Dream", "Falcon", "Tiger", "Echo"]

    
    
    func extractWords(from variables: [String]) {
        let pattern = "([A-Z]?[a-z]+)"
        let regex = try! NSRegularExpression(pattern: pattern)

        for name in variables {
            let matches = regex.matches(in: name, range: NSRange(name.startIndex..., in: name))
            var words: [String] = matches.map {
                String(name[Range($0.range, in: name)!])
            }
            
            // Перше слово з великої літери
            if let first = words.first {
                words[0] = first.capitalized
            }
            
            // Додаємо всі слова у множину
            for word in words {
                englishWordsSet.insert(word)
            }
        }
    }
    
    
    
    func generateObfuscationMap(from variables: [VariableInfo]) {
        
        let onlyVariables = variables.map { $0.variableName }
        let onlyTypeName = variables.map { $0.typeName }
        let variablesAndTypeName = onlyVariables + onlyTypeName
        extractWords(from: variablesAndTypeName)
        
        
        let grouped = Dictionary(grouping: variables, by: { $0.typeName })

        for (type, items) in grouped {
            var usedPrefixes = Set<String>()
            var usedSuffixes = Set<String>()
            var variableMap: [String: String] = [:]
            var methodMap: [String: String] = [:]

            for item in items {
//                let firstWord = extractFirstWord(from: item.variableName)
//                let shortPrefix = abbreviatedFirstWord(from: firstWord)

                var prefix: String
                repeat {
                    prefix = englishWordsSet.randomElement() ?? UUID().uuidString
//                    suffix = englishWords.randomElement() ?? UUID().uuidString
                } while usedPrefixes.contains(prefix)
                usedPrefixes.insert(prefix)
                
                var suffix: String
                repeat {
                    suffix = englishWordsSet.randomElement() ?? UUID().uuidString
//                    suffix = englishWords.randomElement() ?? UUID().uuidString
                } while usedSuffixes.contains(suffix)
                usedSuffixes.insert(suffix)

                let obfuscatedName = prefix.lowercased() + suffix
//                let obfuscatedName = shortPrefix + suffix


                if item.isMethod {
                    methodMap[item.variableName] = obfuscatedName
                } else {
                    variableMap[item.variableName] = obfuscatedName
                }
            }

            if !variableMap.isEmpty {
                variableObfuscationMap[type] = variableMap
            }
            if !methodMap.isEmpty {
                methodObfuscationMap[type] = methodMap
            }
        }
    }


    private func extractFirstWord(from camelCase: String) -> String {
        let pattern = "^[a-z]+"
        if let range = camelCase.range(of: pattern, options: .regularExpression) {
            return String(camelCase[range])
        }
        return camelCase
    }
    
    
    func abbreviatedFirstWord(from firstWord: String) -> String {
            if firstWord.count >= 2 {
                let firstChar = firstWord.first!
                let lastChar = firstWord.last!
                return "\(firstChar)\(lastChar)"
            } else {
                return firstWord // якщо перше слово коротше ніж 2 літери
            }
    }

    
    func obfuscateCode(in fileURL: URL, instanceToType: [String: String], userDefinedTypes: Set<String>) {
        guard var content = try? String(contentsOf: fileURL) else { return }
        
        var ignoredParams: Set<String> = ["path", "response", "parse", "serialize", "response", "data", "error", "decode", "from", "main", "queue", "responseSerializer", "errorParser", "multipartFormData", "upload", "to", "result", "success", "failure", "sessionManager", "request", "get", "set", "headers", "salt", "range",  "run", "size", "environment", "connect", "key", "value", "context", "remove",  "height",  "info", "completionHandler", "center",
        ]
        
        // MARK: - Частина 1.1.: Ланцюжки викликів типу A.B.C.method(...) або з нового рядка .method(...)
        let chainPattern = #"(?<!\w)([A-Z]\w*(?:<[^>]+>)?)?(?:\s*\n)?((?:\.\w+)+)\s*\((.*?)\)"#
        
        if let regex = try? NSRegularExpression(pattern: chainPattern, options: [.dotMatchesLineSeparators]) {
            let matches = regex.matches(in: content, range: NSRange(content.startIndex..<content.endIndex, in: content))
            
            for match in matches {
                guard
                    let typeRange = Range(match.range(at: 1), in: content),
                    let chainRange = Range(match.range(at: 2), in: content)
                else { continue }
                
                let typeName = String(content[typeRange])
                let chain = String(content[chainRange]) // .a.b.c
                
                // 🔧 Виправлення: працюємо і з пустим typeName (SwiftUI стиль)
                if typeName.isEmpty || !userDefinedTypes.contains(typeName) {
                    /*
                    let parts = chain
                        .split(separator: ".")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                    
                    ignoredParams.formUnion(parts)
                     */
                    let chainParts = chain
                        .components(separatedBy: ".")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }

                    ignoredParams.formUnion(chainParts)
                    
                    // 🔽 Параметри всередині дужок (...), незалежно від рядків
                    if let paramsRange = Range(match.range(at: 3), in: content) {
                        let paramsString = String(content[paramsRange])
                        let paramPattern = #"\b(\w+)\s*:"#
                        if let paramRegex = try? NSRegularExpression(pattern: paramPattern) {
                            let paramMatches = paramRegex.matches(
                                in: paramsString,
                                range: NSRange(paramsString.startIndex..<paramsString.endIndex, in: paramsString)
                            )
                            for paramMatch in paramMatches {
                                if let nameRange = Range(paramMatch.range(at: 1), in: paramsString) {
                                    ignoredParams.insert(String(paramsString[nameRange]))
                                }
                            }
                        }
                    }
                }
            }
        }
    
        
        // MARK: - Частина 1.2.: Збираємо зовнішні екземпляри (client = Something.something)
        var externalInstances = Set<String>()
        let assignmentPattern = #"(\w+)\s*=\s*[A-Z]\w*(?:<[^>]+>)?(?:\.\w+)+\s*\(.*?\)"#
        if let assignRegex = try? NSRegularExpression(pattern: assignmentPattern, options: [.dotMatchesLineSeparators]) {
            let assignMatches = assignRegex.matches(in: content, range: NSRange(content.startIndex..<content.endIndex, in: content))
            for assignMatch in assignMatches {
                if assignMatch.numberOfRanges > 1,
                   let nameRange = Range(assignMatch.range(at: 1), in: content) {
                    let instanceName = String(content[nameRange])
                    externalInstances.insert(instanceName)
                }
            }
        }

        // MARK: - Частина 1.3:  Для кожного такого екземпляру — шукаємо всі доступи типу client.x.y(...)
        for instance in externalInstances {
            // \b щоб не чіпати подібні до "myclient"
            let accessPattern = #"(?<!\w)\b\#(instance)((?:\.\w+)+)(?:\s*\((.*?)\))?"#
            if let accessRegex = try? NSRegularExpression(pattern: accessPattern, options: [.dotMatchesLineSeparators]) {
                let accessMatches = accessRegex.matches(in: content, range: NSRange(content.startIndex..<content.endIndex, in: content))

                for accessMatch in accessMatches {
                    // Доступи типу .files.upload
                    guard accessMatch.numberOfRanges > 2,
                          let chainRange = Range(accessMatch.range(at: 2), in: content)
                    else { continue }

                    let chain = String(content[chainRange])
                    let parts = chain
                        .components(separatedBy: ".")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }

                    ignoredParams.formUnion(parts)

                    // Також додаємо параметри, якщо є
                    if accessMatch.numberOfRanges > 3,
                       let paramRange = Range(accessMatch.range(at: 3), in: content) {
                        let paramString = String(content[paramRange])
                        let paramPattern = #"\b(\w+)\s*:"#
                        if let paramRegex = try? NSRegularExpression(pattern: paramPattern) {
                            let paramMatches = paramRegex.matches(
                                in: paramString,
                                range: NSRange(paramString.startIndex..<paramString.endIndex, in: paramString)
                            )
                            for paramMatch in paramMatches {
                                if let nameRange = Range(paramMatch.range(at: 1), in: paramString) {
                                    ignoredParams.insert(String(paramString[nameRange]))
                                }
                            }
                        }
                    }
                }
            }
        }

      
        // MARK: - Частина 1-б: SwiftUI-style методи з нового рядка: .methodName(param1:, param2:)
        let swiftUIMethodPattern = #"(?m)^\s*\.(\w+)\s*\(([^)]*)\)"#

        if let regex = try? NSRegularExpression(pattern: swiftUIMethodPattern, options: [.dotMatchesLineSeparators]) {
            let matches = regex.matches(in: content, range: NSRange(content.startIndex..<content.endIndex, in: content))

            for match in matches {
                guard
                    let methodRange = Range(match.range(at: 1), in: content),
                    let paramsRange = Range(match.range(at: 2), in: content)
                else { continue }

                let methodName = String(content[methodRange])
                ignoredParams.insert(methodName)

                let paramsString = String(content[paramsRange])
                let paramPattern = #"\b(\w+)\s*:"#
                if let paramRegex = try? NSRegularExpression(pattern: paramPattern) {
                    let paramMatches = paramRegex.matches(
                        in: paramsString,
                        range: NSRange(paramsString.startIndex..<paramsString.endIndex, in: paramsString)
                    )
                    for paramMatch in paramMatches {
                        if let nameRange = Range(paramMatch.range(at: 1), in: paramsString) {
                            ignoredParams.insert(String(paramsString[nameRange]))
                        }
                    }
                }
            }
        }

        // MARK: - Частина 1-в: error у блоках catch
        let catchErrorPattern = #"catch\s*(?:\(\s*(\w+)?\s*\))?\s*\{((?:[^{}]|\{[^{}]*\})*)\}"#

        if let regex = try? NSRegularExpression(pattern: catchErrorPattern, options: [.dotMatchesLineSeparators]) {
            let matches = regex.matches(in: content, range: NSRange(content.startIndex..<content.endIndex, in: content))

            for match in matches {
                let errorVarName: String = {
                    if match.numberOfRanges > 1, let nameRange = Range(match.range(at: 1), in: content) {
                        return String(content[nameRange])
                    } else {
                        return "error"
                    }
                }()

                guard match.numberOfRanges > 2,
                      let bodyRange = Range(match.range(at: 2), in: content) else {
                    continue
                }

                let catchBody = String(content[bodyRange])
                ignoredParams.insert(errorVarName)

                // Знаходимо error.something
                let subPattern = #"(?<!\w)\#(errorVarName)\.(\w+)"#
                if let subRegex = try? NSRegularExpression(pattern: subPattern) {
                    let subMatches = subRegex.matches(in: catchBody, range: NSRange(catchBody.startIndex..<catchBody.endIndex, in: catchBody))
                    for subMatch in subMatches {
                        if subMatch.numberOfRanges > 2,
                           let nameRange = Range(subMatch.range(at: 2), in: catchBody) {
                            ignoredParams.insert(String(catchBody[nameRange]))
                        }
                    }
                }
            }
        }
        
        // MARK: - Частина 1-д: work with "get" and "set"
        let accessorPattern = #"""
        (?:var|let)\s+\w+\s*:\s*[^{}=\n]+\{\s*((?:\w+|\w+\s*\(\s*\w*\s*\))(\s*;\s*(\w+|\w+\s*\(\s*\w*\s*\)))?)\s*\}
        """#

        if let accessorRegex = try? NSRegularExpression(pattern: accessorPattern, options: [.dotMatchesLineSeparators]) {
            let matches = accessorRegex.matches(in: content, range: NSRange(content.startIndex..<content.endIndex, in: content))

            for match in matches {
                if match.numberOfRanges > 1,
                   let fullAccessorsRange = Range(match.range(at: 1), in: content) {
                    let accessorLine = content[fullAccessorsRange]
                    // Розбиваємо за `;` або пробілом
                    let tokens = accessorLine
                        .replacingOccurrences(of: "(", with: "")
                        .replacingOccurrences(of: ")", with: "")
                        .split(whereSeparator: { $0 == " " || $0 == ";" })

                    for token in tokens {
                        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            ignoredParams.insert(trimmed)
                        }
                    }
                }
            }
        }


        // MARK: - Частина 2: Простий виклик типу SomeType(param1: param2:)
        let paramsPattern = #"(?<!\w)([A-Z]\w*(?:<[^>]+>)?)?\s*\((.*?)\)"#

        if let regex = try? NSRegularExpression(pattern: paramsPattern, options: [.dotMatchesLineSeparators]) {
            let matches = regex.matches(in: content, range: NSRange(content.startIndex..<content.endIndex, in: content))
            
            for match in matches {
                guard let typeRange = Range(match.range(at: 1), in: content),
                      let paramsRange = Range(match.range(at: 2), in: content)
                else { continue }

                let typeName = String(content[typeRange])
                let paramsString = String(content[paramsRange])

                if !userDefinedTypes.contains(typeName) {
                    let paramPattern = #"\b(\w+)\s*:"#
                    if let paramRegex = try? NSRegularExpression(pattern: paramPattern) {
                        let paramMatches = paramRegex.matches(in: paramsString, range: NSRange(paramsString.startIndex..<paramsString.endIndex, in: paramsString))
                        for paramMatch in paramMatches {
                            if let nameRange = Range(paramMatch.range(at: 1), in: paramsString) {
                                ignoredParams.insert(String(paramsString[nameRange]))
                            }
                        }
                    }
                }
            }
        }
        
        
        

        // 1. Отримуємо всі відомі локальні типи
        let knownTypes = Set(variableObfuscationMap.keys).union(methodObfuscationMap.keys)

        // 2. Фільтруємо instanceToType: залишаємо лише ті, що мають локальні типи
        let localInstanceToType = instanceToType.filter { knownTypes.contains($0.value) }

        // 3. Обфускація змінних
        for (typeName, mapping) in variableObfuscationMap {
            
            guard userDefinedTypes.contains(typeName) else {
                continue
            }
            
            for (original, obfuscated) in mapping {
                
                if ignoredParams.contains(original) { continue }

                let basePatterns: [(pattern: String, template: String)] = [
                    ("\\bself\\.\(original)\\b", "self.\(obfuscated)"),
                    ("(?<!\\w)\(original)\\b(?!\\s*\\()", obfuscated)
                ]
     
                
                let nestedPatterns: [(pattern: String, template: String)] = localInstanceToType
                    .filter { $0.value == typeName }
                    .flatMap { instance, _ in
                        if let otherType = localInstanceToType[original], otherType != typeName {
                            return [(pattern: String, template: String)]()
                        }

                        let negativeLookahead = #"(?!(\s*\()|(\s*\{)|(\s+async\b)|(\s+await\b))"#

                        return [
                            ("\\bself\\.\(instance)\\.\(original)\\b", "self.\(instance).\(obfuscated)"),
                            ("(?<!\\w)\(instance)\\.\(original)\\b\(negativeLookahead)", "\(instance).\(obfuscated)")
                        ]
                    }
                
                
                
                // Патерн для completionHandler()
                var handlerPatterns: [(pattern: String, template: String)] = []
                if original == "completionHandler" {
                    handlerPatterns = [
                        ("\\bcompletionHandler\\b(?=\\s*\\()", obfuscated)
                    ]
                }

                let allPatterns = basePatterns + nestedPatterns + handlerPatterns

                for (pattern, template) in allPatterns {
                    if let regex = try? NSRegularExpression(pattern: pattern) {
                        let range = NSRange(content.startIndex..<content.endIndex, in: content)
                        content = regex.stringByReplacingMatches(in: content, options: [], range: range, withTemplate: template)
                    }
                }
            }
        }

        // 4. Обфускація методів
        for (typeName, mapping) in methodObfuscationMap {
            
            guard userDefinedTypes.contains(typeName) else { continue }
            
            for (original, obfuscated) in mapping {
                
                if ignoredParams.contains(original) { continue }
                
                let basePatterns: [(pattern: String, template: String)] = [
                    ("\\bself\\.\(original)\\b(?=\\s*\\()", "self.\(obfuscated)"),
                    ("(?<!\\w)\(original)\\b(?=\\s*\\()", obfuscated),

                    // Метод як посилання (без дужок)
                    ("\\bself\\.\(original)\\b(?!\\s*\\()", "self.\(obfuscated)"),
                    ("(?<!\\w)\(original)\\b(?!\\s*\\()", obfuscated)
                ]

                let nestedPatterns: [(pattern: String, template: String)] = localInstanceToType
                    .filter { $0.value == typeName }
                    .flatMap { instance, _ in
                        return [
                            ("\\bself\\.\(instance)\\.\(original)\\b(?=\\s*\\()", "self.\(instance).\(obfuscated)"),
                            ("(?<!\\w)\(instance)\\.\(original)\\b(?=\\s*\\()", "\(instance).\(obfuscated)")
                        ]
                    }

                let allPatterns = basePatterns + nestedPatterns

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

    
    
    func obfuscateCodeOLD2_donotTested(in fileURL: URL, instanceToType: [String: String]) {
        guard var content = try? String(contentsOf: fileURL) else { return }

        // Обфускація змінних
        for (typeName, mapping) in variableObfuscationMap {
            for (original, obfuscated) in mapping {
                let basePatterns: [(pattern: String, template: String)] = [
                    ("\\bself\\.\(original)\\b", "self.\(obfuscated)"),
                    ("(?<!\\w)\(original)\\b(?!\\s*\\()", obfuscated)
                ]

                let nestedPatterns: [(pattern: String, template: String)] = instanceToType
                    .filter { $0.value == typeName }
                    .flatMap { instance, _ in
                        return [
                            ("\\bself\\.\(instance)\\.\(original)\\b", "self.\(instance).\(obfuscated)"),
                            ("(?<!\\w)\(instance)\\.\(original)\\b(?!\\s*\\()", "\(instance).\(obfuscated)")
                        ]
                    }

                let allPatterns = basePatterns + nestedPatterns

                for (pattern, template) in allPatterns {
                    if let regex = try? NSRegularExpression(pattern: pattern) {
                        let range = NSRange(content.startIndex..<content.endIndex, in: content)
                        content = regex.stringByReplacingMatches(in: content, options: [], range: range, withTemplate: template)
                    }
                }
            }
        }

        // Обфускація методів
        for (typeName, mapping) in methodObfuscationMap {
            for (original, obfuscated) in mapping {
                let basePatterns: [(pattern: String, template: String)] = [
                    ("\\bself\\.\(original)\\b(?=\\s*\\()", "self.\(obfuscated)"),
                    ("(?<!\\w)\(original)\\b(?=\\s*\\()", obfuscated)
                ]

                let nestedPatterns: [(pattern: String, template: String)] = instanceToType
                    .filter { $0.value == typeName }
                    .flatMap { instance, _ in
                        return [
                            ("\\bself\\.\(instance)\\.\(original)\\b(?=\\s*\\()", "self.\(instance).\(obfuscated)"),
                            ("(?<!\\w)\(instance)\\.\(original)\\b(?=\\s*\\()", "\(instance).\(obfuscated)")
                        ]
                    }

                let allPatterns = basePatterns + nestedPatterns

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

    
    
    
    
    
    func obfuscateCodeOLD_worked(in fileURL: URL, instanceToType: [String: String]) {
        guard var content = try? String(contentsOf: fileURL) else { return }
        var count = 0
        
        for (typeName, mapping) in                 variableObfuscationMap {
            count += 1
            for (original, obfuscated) in mapping {
                // Базові патерни: self.property і просто property
                let basePatterns: [(pattern: String, template: String)] = [
                    ("\\bself\\.\(original)\\b", "self.\(obfuscated)"),
                    ("(?<!\\w)\(original)\\b(?!\\s*\\()", obfuscated)
                ]

                // Вкладені виклики через екземпляри об'єктів
                let nestedPatterns: [(pattern: String, template: String)] = instanceToType
                    .filter { $0.value == typeName }
                    .flatMap { instance, _ in
                        return [
                            ("\\bself\\.\(instance)\\.\(original)\\b", "self.\(instance).\(obfuscated)"),
                            ("(?<!\\w)\(instance)\\.\(original)\\b(?!\\s*\\()", "\(instance).\(obfuscated)")
                        ]
                    }
                // Патерн для completionHandler()
                var handlerPatterns: [(pattern: String, template: String)] = []
                if original == "completionHandler" {
                    handlerPatterns = [
                        ("\\bcompletionHandler\\b(?=\\s*\\()", obfuscated)
                    ]
                }
                
                // Об’єднуємо всі патерни
                let allPatterns = basePatterns + nestedPatterns + handlerPatterns

                // Застосовуємо обфускацію
                for (pattern, template) in allPatterns {
                    if let regex = try? NSRegularExpression(pattern: pattern) {
                        let range = NSRange(content.startIndex..<content.endIndex, in: content)
                        content = regex.stringByReplacingMatches(in: content, options: [], range: range, withTemplate: template)
                    }
//                    try? content.write(to: fileURL, atomically: true, encoding: .utf8)
                }
            }
        }

        try? content.write(to: fileURL, atomically: true, encoding: .utf8)
    }


}

