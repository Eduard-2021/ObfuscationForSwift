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
            pattern: #"(?<!case\s)(?:@\w+\s+)*(?:(?:private|public|internal|fileprivate|static)\s+)*\b(let|var)\s+(\w+)"#,
            options: []
        )
        let methodRegex = try! NSRegularExpression(
            pattern: #"(?:(?:@\w+\s+)|(?:\b(?:public|private|internal|fileprivate|open|static|class|mutating|nonmutating|override)\s+))*func\s+(\w+)"#,
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



