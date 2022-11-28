//
//  BonjourTestApp.swift
//  Shared
//
//  Created by 梅澤真史 on 2022/09/09.
//

import Foundation
import SwiftUI
import os.log

func suylog(_ message: String) {
    #if DEBUG
    let log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "Mesh-UI")
    os_log("%@", log: log, type: .debug, message)
    #endif
}

@available(iOS 14.0, *)
extension Color {
    static let backgroundColor = Color(red: 212/255, green: 212/255, blue: 212/255)
    static let headerBackgroundColor = Color(red: 170/255, green: 170/255, blue: 170/255)
    static let buttonBackgroundColor = Color(UIColor.white).opacity(0.6)
    static let deactivatedColor = Color(UIColor.systemGray)
}

@available(iOS 14.0, *)
class MeshUIViewFactory: NSObject {
  @objc static func makeMeshUiViewController(dismissHandler: @escaping (() -> Void)) -> UIViewController {
    return UIHostingController(rootView: MeshSettingsView(dismiss: dismissHandler))
  }
}
