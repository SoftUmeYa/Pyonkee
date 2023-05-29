//
//  MeshUiUtils.swift
//
//  Created by 梅澤真史 on 2022/09/09.
//

import Foundation
import Network
import SwiftUI
import os.log

func suylog(_ message: String) {
    #if DEBUG
    let log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "Mesh-UI")
    os_log("%@", log: log, type: .debug, message)
    #endif
}

func newNetworkPathMonitor() -> NWPathMonitor{
    if #available(iOS 14.0, *) {
        return NWPathMonitor(prohibitedInterfaceTypes: [.loopback, .cellular])
    } else {
        return NWPathMonitor(requiredInterfaceType: .wifi)
    }
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

extension NWInterface.InterfaceType {
    var names : [String]? {
        switch self {
        case .wifi: return ["en0"]
        case .wiredEthernet: return ["en2", "en3", "en4"]
        case .cellular: return ["pdp_ip0","pdp_ip1","pdp_ip2","pdp_ip3"]
        default: return nil
        }
    }

    func address(family: Int32) -> String?
    {
        guard let names = names else { return nil }
        var address : String?
        for name in names {
            guard let nameAddress = self.address(family: family, name: name) else { continue }
            address = nameAddress
            break
        }
        return address
    }

    func address(family: Int32, name: String) -> String? {
        var address: String?

        // Get list of all interfaces on the local machine:
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return nil }

        // For each interface ...
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee

            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(family)
            {
                // Check interface name:
                if name == String(cString: interface.ifa_name) {
                    // Convert interface address to a human readable string:
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        freeifaddrs(ifaddr)

        return address
    }

    var ipv4 : String? { self.address(family: AF_INET) }
    var ipv6 : String? { self.address(family: AF_INET6) }
}
