//
//  MainViewModel.swift
//  Obfuscare
//
//  Created by Macintosh HD on 14.07.2025.
//

import SwiftUI

class MainViewModel: ObservableObject {
    
    //MARK: - Properties
    
    @Published var isShowAlert = false
    @Published var isProgressViewShow = false
    
    var messageOfAlert = "All finished"
    
    let projectScanner = ProjectScanner()
    let detector = CamelCaseDetector()
    let instanceDetector = InstanceDetector()
    let obfuscator = Obfuscator()
    
    /*
    func runObfuscation() {

     let pattern = #"""
     (?:(?:@?\w+\s+)*)(?:private\s+|public\s+|internal\s+|static\s+|lazy\s+|weak\s+|final\s+)*\b(var|let)\s+(?!body\b)(?!some\b)(?!Scene\b)(?!App\b)(\w+)\s*(?::\s*([\w<>\.]+)\??)?(?:\s*=\s*([\w\.]+)\s*\([^)]*\))?
     """#
     let regex = try! NSRegularExpression(pattern: pattern, options: [])
     let content = """
     @StateObject var mainExperiment3 = MainViewModel()
     var mainExperiment3: MainViewModel = MainViewModel()
     var name: String
     """

        let matches = regex.matches(in: content, options: [], range: NSRange(content.startIndex..., in: content))

        for match in matches {
            let varLet = Range(match.range(at: 1), in: content).flatMap { String(content[$0]) } ?? "-"
            let name = Range(match.range(at: 2), in: content).flatMap { String(content[$0]) } ?? "-"
            let typeFromAnnotation = Range(match.range(at: 3), in: content).flatMap { String(content[$0]) }
            let typeFromInit = Range(match.range(at: 4), in: content).flatMap { String(content[$0]) }
            let finalType = typeFromAnnotation ?? typeFromInit ?? "-"
            print("type: \(varLet), name: \(name), class: \(finalType)")
        }
    }
    */
    
    

    func runObfuscation() {
        let rootPath = "/Users/macintoshhd/Documents/Xcode/Work/Test/TestObfuscare1"
        let rootURL = URL(fileURLWithPath: rootPath)
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
        isShowAlert = true
    }
    
    /*
    func startObfuscare(){
        let detector = CamelCaseDetector(projectPath: "/Users/macintoshhd/Documents/Xcode/Work/Test/TestObfuscare1")
        let variables = detector.scanProject()

        let obfuscator = Obfuscator()
        obfuscator.obfuscate(variables: variables)
        
    }
    */
    
    /*
    func replaceTextInFiles(in directoriesPath: [String], target: String, replacement: String, completionHandler: @escaping () -> Void) {
        let fileManager = FileManager.default
        for directoryPath in directoriesPath {
            var resolvedPath = directoryPath
            if resolvedPath.contains("~") {
                resolvedPath = NSString(string: directoryPath).expandingTildeInPath
            }
            let directoryURL = URL(fileURLWithPath: resolvedPath)
            
            guard let enumerator = fileManager.enumerator(at: directoryURL, includingPropertiesForKeys: nil) else {
                print("Не вдалося отримати список файлів у директорії.")
                errorInAlert()
                continue
            }
            
            for case let fileURL as URL in enumerator {
                guard fileURL.hasDirectoryPath == false else {
                    continue
                }
                
                do {
                    var content = try String(contentsOf: fileURL, encoding: .utf8)
                    if content.contains(target) {
                        content = content.replacingOccurrences(of: target, with: replacement)
                        try content.write(to: fileURL, atomically: true, encoding: .utf8)
                        print("Оновлено файл: \(fileURL.path)")
                    } else {
                        print("Файл не містить \(target): \(fileURL.path)")
                    }
                } catch {
                    print("Помилка при обробці файлу \(fileURL.path): \(error.localizedDescription)")
                }
            }
        }
        
        DispatchQueue.main.async {
            completionHandler()
        }
    }
    
    
    func errorInAlert(){
        messageOfAlert = "Error with obfuscare"
        DispatchQueue.main.async {
            self.isProgressViewShow = false
            self.isShowAlert = true
        }
    }
    */
}
