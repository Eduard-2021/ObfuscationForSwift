//
//  Obfuscator.swift
//  Obfuscare
//
//  Created by Macintosh HD on 15.07.2025.
//

import Foundation

class Obfuscator {
    var obfuscationMap: [String: [String: String]] = [:] // typeName -> [original: obfuscated]
    var methodObfuscationMap: [String: [String: String]] = [:]
    
    private let englishWords = variableNames
    /*[
        "Exp23_07_01","Exp23_07_02","Exp23_07_03","Exp23_07_04","Exp23_07_05","Exp23_07_06","Exp23_07_07","Exp23_07_08","Exp23_07_09","Exp23_07_010",
        "Exp23_07_011","Exp23_07_012","Exp23_07_013","Exp23_07_014","Exp23_07_015","Exp23_07_016","Exp23_07_017","Exp23_07_018","Exp23_07_019","Exp23_07_020","Exp23_07_021","Exp23_07_022","Exp23_07_023","Exp23_07_024","Exp23_07_025","Exp23_07_026","Exp23_07_027","Exp23_07_028","Exp23_07_029","Exp23_07_030","Exp23_07_031","Exp23_07_032","Exp23_07_033","Exp23_07_034","Exp23_07_035","Exp23_07_036","Exp23_07_037","Exp23_07_038","Exp23_07_039","Exp23_07_040","Exp23_07_041","Exp23_07_042","Exp23_07_043",
            ,"Exp23_07_036","Exp23_07_037","Exp23_07_038","Exp23_07_039","Exp23_07_040","Exp23_07_041","Exp23_07_042","Exp23_07_043",
    ]
    */
    
    
//    let englishWords = ["Apple", "Orange", "Cloud", "Rocket", "Dream", "Falcon", "Tiger", "Echo"]

    func generateObfuscationMap(from variables: [VariableInfo]) {
        let grouped = Dictionary(grouping: variables, by: { $0.typeName })

        for (type, items) in grouped {
            var usedSuffixes = Set<String>()
            var variableMap: [String: String] = [:]
            var methodMap: [String: String] = [:]

            for item in items {
                let firstWord = extractFirstWord(from: item.variableName)
                let shortPrefix = abbreviatedFirstWord(from: firstWord)

                var suffix: String
                repeat {
                    suffix = englishWords.randomElement() ?? UUID().uuidString
                } while usedSuffixes.contains(suffix)
                usedSuffixes.insert(suffix)

                let obfuscatedName = shortPrefix + suffix

                if item.isMethod {
                    methodMap[item.variableName] = obfuscatedName
                } else {
                    variableMap[item.variableName] = obfuscatedName
                }
            }

            if !variableMap.isEmpty {
                obfuscationMap[type] = variableMap
            }
            if !methodMap.isEmpty {
                methodObfuscationMap[type] = methodMap
            }
        }
    }

    
    
    
    /*
    func generateObfuscationMap(from variables: [VariableInfo]) {
        let grouped = Dictionary(grouping: variables, by: { $0.typeName })

        for (type, vars) in grouped {
            var usedSuffixes = Set<String>()
            var nameMap: [String: String] = [:]

            for variable in vars {
                let firstWord = extractFirstWord(from: variable.variableName)
                var suffix: String
                
                let shortPrefix = abbreviatedFirstWord(from: firstWord)

                repeat {
                    suffix = englishWords.randomElement() ?? UUID().uuidString
                } while usedSuffixes.contains(suffix)

                usedSuffixes.insert(suffix)
                nameMap[variable.variableName] = shortPrefix + suffix
            }

            obfuscationMap[type] = nameMap
        }
    }
    */

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
    
    
    func obfuscateCodeOLD4(in fileURL: URL, instanceToType: [String: String], userDefinedTypes: Set<String>) {
        guard var content = try? String(contentsOf: fileURL) else { return }

        for (typeName, mapping) in obfuscationMap {
            // Пропускаємо типи, яких немає серед оголошених у коді
            guard userDefinedTypes.contains(typeName) else {
                continue
            }

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

                let handlerPatterns: [(pattern: String, template: String)] =
                    original == "completionHandler"
                        ? [("\\bcompletionHandler\\b(?=\\s*\\()", obfuscated)]
                        : []

                let allPatterns = basePatterns + nestedPatterns + handlerPatterns

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

    
    
    
    func obfuscateCode(in fileURL: URL, instanceToType: [String: String], userDefinedTypes: Set<String>) {
        guard var content = try? String(contentsOf: fileURL) else { return }

            /*
        // 1. Визначаємо імена змінних-параметрів, які не можна змінювати
        var ignoredParams = Set<String>()
        // Pattern для складних ланцюжків з крапками
        let complexPattern = #"""
        (?<!\w)(([A-Z]\w*)(?:<[^>]+>)?(?:\.\w+)+)\s*\([^)]*?\b(\w+)\s*:
        """#

        // Додатковий pattern для простих викликів типу SomeType(paramName:)
        let simplePattern = #"""
        (?<!\w)([A-Z]\w*)(?:<[^>]+>)?\s*\([^)]*?\b(\w+)\s*:
        """#

        // Аналізуємо обидва патерни
        for (pattern, isComplex) in [(complexPattern, true), (simplePattern, false)] {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let matches = regex.matches(in: content, range: NSRange(content.startIndex..<content.endIndex, in: content))
                for match in matches {
                    guard
                        let typeRange = Range(match.range(at: 1), in: content),
                        let paramRange = Range(match.range(at: isComplex ? 3 : 2), in: content)
                    else { continue }

                    let typePart = String(content[typeRange])
                    let paramName = String(content[paramRange])

                    // Отримуємо тип (без крапок та generic)
                    let typeName = typePart.components(separatedBy: ".").first?.components(separatedBy: "<").first ?? typePart

                    if !userDefinedTypes.contains(typeName) {
                        // У складному — додаємо всі з ланцюжка + параметр
                        if isComplex {
                            let identifiers = typePart.components(separatedBy: ".").filter { !$0.contains("<") && !$0.isEmpty }
                            identifiers.forEach { ignoredParams.insert($0) }
                        }
                        ignoredParams.insert(paramName)
                    }
                }
            }
        }
             */
        
        
        
        
        var ignoredParams = Set<String>()
        // MARK: - Частина 1: Ланцюжки викликів типу A.B.C.method(...) або з нового рядка .method(...)
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
                    let parts = chain
                        .split(separator: ".")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }

                    ignoredParams.formUnion(parts)

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


        
        /*
        // MARK: - Частина 1: Ланцюжки викликів типу A.B.C.method(...)
        let chainPattern = #"(?<!\w)([A-Z]\w*(?:<[^>]+>)?)((?:\.\w+)+)\s*\((.*?)\)"#

        if let regex = try? NSRegularExpression(pattern: chainPattern, options: [.dotMatchesLineSeparators]) {
            let matches = regex.matches(in: content, range: NSRange(content.startIndex..<content.endIndex, in: content))
            
            for match in matches {
                guard
                    let typeRange = Range(match.range(at: 1), in: content),
                    let chainRange = Range(match.range(at: 2), in: content)
                else { continue }

                let typeName = String(content[typeRange])
                let chain = String(content[chainRange]) // .a.b.c

                if !userDefinedTypes.contains(typeName) {
                    let parts = chain.split(separator: ".").map { String($0) }
                    ignoredParams.formUnion(parts)

                    // 🔽 Параметри
                    if let paramsRange = Range(match.range(at: 3), in: content) {
                        let paramsString = String(content[paramsRange])
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
        }
            */
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
        let knownTypes = Set(obfuscationMap.keys).union(methodObfuscationMap.keys)

        // 2. Фільтруємо instanceToType: залишаємо лише ті, що мають локальні типи
        let localInstanceToType = instanceToType.filter { knownTypes.contains($0.value) }

        // 3. Обфускація змінних
        for (typeName, mapping) in obfuscationMap {
            
            guard userDefinedTypes.contains(typeName) else { continue }
            
            for (original, obfuscated) in mapping {
                
                if ignoredParams.contains(original) { continue }

                let basePatterns: [(pattern: String, template: String)] = [
                    ("\\bself\\.\(original)\\b", "self.\(obfuscated)"),
                    ("(?<!\\w)\(original)\\b(?!\\s*\\()", obfuscated)
                ]

                let nestedPatterns: [(pattern: String, template: String)] = localInstanceToType
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
        for (typeName, mapping) in obfuscationMap {
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
        
        for (typeName, mapping) in obfuscationMap {
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

