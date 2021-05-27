//
//  SUYMicrobitUtils.swift
//  Scratch
//
//  Created by 梅澤 真史 on 2021/04/14.
//

import UIKit

import SDCAlertView

class SUYMicrobitUtils: NSObject {
    
    //MARK: Factory
    @objc class public func createAlertController (_ message: String) -> AlertController {
        let alert = AlertController(title: "micro:bit", message: message)
        alert.behaviors = alert.behaviors.union(.dismissOnOutsideTap)
        alert.actionLayout = .vertical
        alert.shouldDismissHandler = {
            if ($0!.accessibilityIdentifier == "close") {return true}
            $0!.handler?($0!)
            return false
        }
        return alert
    }
    
    //MARK: Actions
    @objc class public func copySampleFiles () -> Bool {
        let microbitPathComponentName = "Microbit"
        let baseProjectDirPath = SUYUtils.bundleResourceDirectory(with: "Projects")
        let docDirectoryPath = SUYUtils.documentDirectory()
        let samplesSourceUrl = URL(fileURLWithPath: baseProjectDirPath!).appendingPathComponent(microbitPathComponentName)
        let samplesDestUrl = URL(fileURLWithPath: docDirectoryPath!).appendingPathComponent(microbitPathComponentName)
        
        let fileMan = FileManager.default
        guard let fileNames = try? fileMan.contentsOfDirectory(atPath: samplesSourceUrl.path) else { return false }
        if fileMan.fileExists(atPath: samplesDestUrl.path) == false {
            do {
                try fileMan.createDirectory(atPath: samplesDestUrl.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error.localizedDescription)
                return false
            }
        }
        for eachFile in fileNames {
            let sourceFileUrl = samplesSourceUrl.appendingPathComponent(eachFile)
            let destFileUrl = samplesDestUrl.appendingPathComponent(eachFile)
            do {
                if (fileMan.fileExists(atPath: destFileUrl.path) == false) {
                    try fileMan.copyItem(at: sourceFileUrl, to: destFileUrl)
                }
            } catch {
                print(error.localizedDescription)
                return false
            }
        }
        return true
    }
    
}
