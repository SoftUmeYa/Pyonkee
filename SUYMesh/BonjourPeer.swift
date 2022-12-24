//
//  BonjourClient.swift
//  BonjourTest
//
//  Created by 梅澤真史 on 2022/09/09.
//

import Foundation
import Network
import Bonjour

@available(iOS 13.0, *)
class BonjourPeer: ObservableObject {
    var session: BonjourSession?
    var isClient: Bool
    @Published var serverPeerNames: [String]
    @Published var isRunning = false;
    
    init(isClient:Bool = false){
        self.isClient = isClient
        self.serverPeerNames = [""]
        suylog("** Peer init: \(self.isClient)")
    }
    
    func start(){
        if(MeshServiceAccessor.isNetReady == false) {return}
        if(self.isRunning == true) {return}
        
        let conf = BonjourSession.Configuration(serviceType: "Pyonkee",
                                                peerName: self.createPeerName(),
                                                    defaults: .standard,
                                                    security: .default,
                                                    invitation: .automatic)
        self.session = BonjourSession(configuration: conf)
        self.setupCallbacks()
        self.session?.start()
        self.isRunning = true
    }
    
    func setupCallbacks(){
        self.session?.onPeerDiscovery = { peer in
            suylog("!!!!!!Found peer \(String(describing: peer.name))")
        }
        self.session?.onPeerConnection = { peer in
            suylog("!!!!!!Connected peer \(String(describing: peer.name))")
        }
        self.session?.onPeerLoss = { peer in
            suylog("!!!!!!Lost peer \(String(describing: peer.name))")
            self.removeServerPeerName(peer.name)
        }
        self.session?.onAvailablePeersDidChange = { peers in
            for peer in peers {
                suylog("!peer \(String(describing: peer))")
            }
            self.setServerPeerNamesFrom(peers.map{$0.name})
        }
        self.session?.onReceive = { data, peer in
            suylog("!!!receive peer \(String(describing: peer))")
            let msg = String(data: data, encoding: .utf8)
            suylog("!!!msg: \(String(describing: msg))")
        }
    }
    
    func stop(){
        self.session?.stop()
        self.isRunning = false
    }
    
    func broadcast(){
        if(self.isRunning == false) {self.start()}
        let ipV4Addr = self.getIpAddress();
        suylog("broadcast: \(ipV4Addr)");
        self.session?.broadcast(ipV4Addr.data(using: .utf8) ?? Data())
    }
    
    func getIpAddress() -> String {
        var address: String?
        address = NWInterface.InterfaceType.wifi.ipv4
        if (address == nil) {
            address = NWInterface.InterfaceType.wiredEthernet.ipv4
        }
        return address ?? ""
    }
    
    // MARK: private
    private func hexStringIPAddressFrom(_ ipAddressString:String) -> String {
        var hexStringIPAddress = ""
        let parts = ipAddressString.components(separatedBy: ".")
        if(parts.count < 4) {
            return ""
        }
        for part in parts {
            let i = Int(part)
            hexStringIPAddress += String(format:"%02X", i!)
        }
        return hexStringIPAddress
    }
    private func createPeerName() -> String {
        var peerName = self.isClient ? "C:" : "S:"
        peerName += self.hexStringIPAddressFrom(self.getIpAddress())
        return peerName
    }
    
    private func setServerPeerNamesFrom(_ rawPeerNames:[String]){
        var names:Set<String> = Set(self.serverPeerNames)
        let serverPeerNames = rawPeerNames.filter({$0.starts(with: "S:")})
        names.formUnion(serverPeerNames.map({
            self.readableIpAddressStringFrom($0)
        }))
        DispatchQueue.main.async {
            self.serverPeerNames = names.sorted()
        }
    }
    private func removeServerPeerName(_ rawPeerName:String){
        if(rawPeerName.starts(with: "S:") == false) {
            return
        }
        var names:Set<String> = Set(self.serverPeerNames)
        names.remove(self.readableIpAddressStringFrom(rawPeerName))
        DispatchQueue.main.async {
            self.serverPeerNames = names.sorted()
        }
    }
    
    private func readableIpAddressStringFrom(_ rawPeerName:String) -> String {
        let addressPart = rawPeerName.components(separatedBy: ":").last
        var addressValue: UInt64 = 0
        guard Scanner(string: addressPart!).scanHexInt64(&addressValue) else {return ""}
        let firstPart = (addressValue & 0xFF000000) >> 24
        let secondPart = (addressValue & 0x00FF0000) >> 16
        let thirdPart = (addressValue & 0x0000FF00) >> 8
        let fourthPart = (addressValue & 0x000000FF)
        return "\(firstPart).\(secondPart).\(thirdPart).\(fourthPart)"
    }
    
}
