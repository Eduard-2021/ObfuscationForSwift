//
//  InstanceDetector.swift
//  Obfuscare
//
//  Created by Macintosh HD on 22.07.2025.
//

import Foundation

class InstanceDetector {
    
    func detectInstances(in fileURL: URL) -> [InstanceInfo] {
        guard let content = try? String(contentsOf: fileURL) else { return [] }
        
        // Основний шаблон, як у тебе — для let/var з типовою ініціалізацією
        let pattern1 = #"""
        (?<!\bguard\s)(?<!\bcase\s)(?:(?:@?\w+\s+)*)(?:private\s+|public\s+|internal\s+|static\s+|lazy\s+|weak\s+|final\s+)*\b(var|let)\s+(?!body\b)(?!some\b)(?!Scene\b)(?!App\b)(\w+)\s*(?::\s*([\w<>\.]+)\??)?(?:\s*=\s*([A-Z][\w\.]*)\s*\([^)]*\))?
        """#

        // Новий шаблон — для випадків типу: let name = SomeClass.staticProperty / staticMethod(...)
        let pattern2 = #"""
        (?:(?:@?\w+\s+)*)(?:private\s+|public\s+|internal\s+|fileprivate\s+|static\s+|lazy\s+|weak\s+|final\s+)?\b(let|var)\s+(\w+)\s*=\s*([A-Z][\w]*)\.(\w+)
        """#
        
        let regexes = [pattern1, pattern2].compactMap {
            try? NSRegularExpression(pattern: $0, options: [])
        }

        var results: [InstanceInfo] = []

        let nsrange = NSRange(content.startIndex..<content.endIndex, in: content)

        for regex in regexes {
            regex.enumerateMatches(in: content, options: [], range: nsrange) { match, _, _ in
                guard let match = match else { return }
                
                let nameRange = Range(match.range(at: 2), in: content)
                if nameRange == nil { return }

                let instanceName = String(content[nameRange!])

                // Pattern 1: бере тип з `:` або з конструктора
                if match.numberOfRanges >= 4 {
                    let typeRange = Range(match.range(at: 3), in: content) ?? Range(match.range(at: 4), in: content)
                    if let typeRange = typeRange {
                        let type = String(content[typeRange])
                        results.append(InstanceInfo(filePath: fileURL.path, instanceName: instanceName, typeName: type))
                    }
                }

                // Pattern 2: тип береться з частини до крапки
                if match.numberOfRanges == 5 {
                    let typeRange = Range(match.range(at: 3), in: content)
                    if let typeRange = typeRange {
                        let type = String(content[typeRange])
                        results.append(InstanceInfo(filePath: fileURL.path, instanceName: instanceName, typeName: type))
                    }
                }
            }
        }
        
        return results
    }

    
    
    
    /*
    func detectInstances(in fileURL: URL) -> [InstanceInfo] {
        guard let content = try? String(contentsOf: fileURL) else { return [] }
        let pattern = #"""
        (?<!\bguard\s)(?<!\bcase\s)(?:(?:@?\w+\s+)*)(?:private\s+|public\s+|internal\s+|static\s+|lazy\s+|weak\s+|final\s+)*\b(var|let)\s+(?!body\b)(?!some\b)(?!Scene\b)(?!App\b)(\w+)\s*(?::\s*([\w<>\.]+)\??)?(?:\s*=\s*([A-Z][\w\.]*)\s*\([^)]*\))?
        """#
        
        let regex = try! NSRegularExpression(pattern: pattern, options: [])

        var results: [InstanceInfo] = []
        let nsrange = NSRange(content.startIndex..<content.endIndex, in: content)

        regex.enumerateMatches(in: content, options: [], range: nsrange) { match, _, _ in
            guard
                let match = match,
                let instanceRange = Range(match.range(at: 2), in: content)
//                    ,
//                let typeRange = Range(match.range(at: 3), in: content)
            else { return }
            
            let typeFromAnnotation = Range(match.range(at: 3), in: content)
            let typeFromInit = Range(match.range(at: 4), in: content)
            
            if typeFromAnnotation != nil || typeFromInit != nil {
                let typeRange = typeFromAnnotation ?? typeFromInit
                let instance = String(content[instanceRange])
                let type = String(content[typeRange!])

                results.append(InstanceInfo(filePath: fileURL.path, instanceName: instance, typeName: type))
                
            } else {
                return
            }
        }
        return results
    }
     */
}
