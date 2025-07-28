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
    

    func runObfuscation() {
//        let rootPath = "/Users/macintoshhd/Documents/Xcode/Work/Test/TestObfuscare1"
//        let rootPath = "/Users/macintoshhd/Documents/Xcode/Work/Test/XSpy_OpenMainCodeForTest(new)"
        let rootPath = "/Users/macintoshhd/Documents/Xcode/Work/Test/TestObfuscare3"
        
        let rootURL = URL(fileURLWithPath: rootPath)
        let swiftFiles = projectScanner.scan(forSwiftFilesIn: rootURL)

//        let allVariables = swiftFiles.flatMap { detector.detectVariables(in: $0) }
        let allVariables = swiftFiles.flatMap { detector.detectVariablesAndMethods(in: $0) }
        obfuscator.generateObfuscationMap(from: allVariables)
        
        let userDefinedTypes = Set(allVariables.map { $0.typeName })

        var instancesPerFile: [String: [String: String]] = [:]
        for file in swiftFiles {
            var instances = instanceDetector.detectInstances(in: file)
            instances.append(InstanceInfo(filePath: file.path, instanceName: "Constants", typeName: "Constants"))
            instancesPerFile[file.path] = Dictionary(instances.map { ($0.instanceName, $0.typeName) }, uniquingKeysWith: { _, new in new })

//            instancesPerFile[file.path] = Dictionary(uniqueKeysWithValues: instances.map { ($0.instanceName, $0.typeName) })
        }
        var count = 0
        var pathString  = ""
        
        for file in swiftFiles {
            count += 1
            pathString = file.path
            let instanceMap = instancesPerFile[file.path] ?? [:]
            obfuscator.obfuscateCode(in: file, instanceToType: instanceMap, userDefinedTypes: userDefinedTypes)
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
