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
//        let pattern = "\\b(var|let)\\s+(\\w+)\\s*:?\\s*(\\w+)\\??\\s*(=\\s*\\w+\\([^)]*\\))?"
//        let pattern = #"\b(var|let)\s+(?!body\b)(?!some\b)(?!Scene\b)(?!App\b)(\w+)\s*:?\\s*(\w+)\??\s*(=\s*\w+\([^)]*\))?"#
//        let pattern = #"(?:@?\w+\s+)*\b(var|let)\s+(?!body\b)(?!some\b)(?!Scene\b)(?!App\b)(\w+)\s*:?[\s]*([\w<>]+)?\??\s*(=\s*\w+\([^)]*\))?"#
//        let pattern = #"""
//        (?:@?\w+\s+|private\s+|public\s+|static\s+|lazy\s+|weak\s+|final\s+)*\b(var|let)\s+(?!body\b)(?!some\b)(?!Scene\b)(?!App\b)(\w+)\s*:?[\s]*([\w<>\.]+)?\??\s*(=\s*\w+\s*\([^)]*\))?
//        """#
//        let pattern = #"""
//        (?:@?\w+\s+|private\s+|public\s+|static\s+|lazy\s+|weak\s+|final\s+)*\b(var|let)\s+(?!body\b)(?!some\b)(?!Scene\b)(?!App\b)(\w+)\s*:?[\s]*([\w<>\.]+)?\??\s*(=\s*[\w\.]+\s*\([^)]*\))?
//        """#
//        let pattern = #"""
//        (?:(?:@?\w+\s+)*)(?:private\s+|public\s+|internal\s+|static\s+|lazy\s+|weak\s+|final\s+)*\b(var|let)\s+(?!body\b)(?!some\b)(?!Scene\b)(?!App\b)(\w+)\s*(?::\s*([\w<>\.]+)\??)?(?:\s*=\s*.+)?
//        """#
        /*
        let pattern = #"""
        (?<!\bguard\s)(?<!\bcase\s)(?:(?:@?\w+\s+)*)(?:private\s+|public\s+|internal\s+|static\s+|lazy\s+|weak\s+|final\s+)*\b(var|let)\s+(?!body\b)(?!some\b)(?!Scene\b)(?!App\b)(\w+)\s*(?::\s*([\w<>\.]+)\??)?(?:\s*=\s*([\w\.]+)\s*\([^)]*\))?
        """#
        */
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
            /*
            let instance = String(content[instanceRange])
            let type = String(content[typeRange])

            results.append(InstanceInfo(filePath: fileURL.path, instanceName: instance, typeName: type))
             */
        }

        return results
    }
}
