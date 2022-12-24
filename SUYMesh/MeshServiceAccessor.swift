//
//  MeshServiceAccessor.swift
//  Pyonkee
//
//  Created by 梅澤真史 on 2022/10/27.
//

import Foundation
import Network

@available(iOS 13.0, *)
class MeshServiceAccessor: NSObject {
    private static var isActivatedAsClient: Bool = false
    private static var isActivatedAsServer: Bool = false
    static var isNetReady: Bool = false
    static var connectedIpAddress: String = ""
    
    private static let netMonitor = newNetworkPathMonitor();
    
    private static let netMonitorQueue = DispatchQueue(label: "netMonitorQueue")
    
    private static let _bonjourPeerServer: BonjourPeer = BonjourPeer()
    
    static func bonjourPeerServer() -> BonjourPeer {
        return _bonjourPeerServer
    }
    static func bonjourPeerClient() -> BonjourPeer {
        return BonjourPeer(isClient: true)
    }

    //MARK: Setup
    static func setup() {
        if(netMonitor.pathUpdateHandler == nil) {
            netMonitor.pathUpdateHandler = { path in
                self.isNetReady = path.status == .satisfied
                if(self.isNetReady == false){
                    DispatchQueue.main.async {
                        self.stopMeshIfActivated()
                    }
                }
            }
            netMonitor.start(queue: netMonitorQueue)
        }
    }
    static func stopMeshIfActivated() {
        if(self.isActivatedAsClient){
            self.leaveMesh()
            self.clearConnectedIpAddress()
        }
        if(self.isActivatedAsServer){
            self.stopMesh()
            _bonjourPeerServer.stop()
        }
    }
    
    //MARK: Testing
    static func isMeshRunning() -> Bool {
        return SUYUtils.meshIsRunning()
    }
    static func isServerActive() -> Bool {
        return self.isActivatedAsServer && self.isMeshRunning()
    }
    static func isClientActive() -> Bool {
        return self.isActivatedAsClient && self.isMeshRunning() 
    }
    static func isAlreadyConnected() -> Bool {
        return self.isMeshMember(self.connectedIpAddress)
    }
    
    //MARK: Client
    static func joinMesh(_ ipAddressString: String){
        if(self.isNetReady == false) {
            return;
        }
        if(self.isActivatedAsServer){
            return
        }
        SUYUtils.meshJoin(ipAddressString)
    }
    static func isMeshMember(_ ipAddressString: String) -> Bool {
        if(self.isNetReady == false) {
            return false;
        }
        if(self.isActivatedAsServer){
            return false
        }
        return SUYUtils.meshJoined(ipAddressString)
    }
    static func leaveMesh() {
        if(self.isActivatedAsServer){
            return;
        }
        self.runMesh(false)
        self.isActivatedAsClient = false
    }
    static func clearConnectedIpAddress() {
        self.connectedIpAddress = ""
    }
    
    //MARK: Server
    static func startMesh() {
        if(self.isNetReady == false) {
            return;
        }
        if(self.isActivatedAsClient){
            return;
        }
        self.runMesh(true);
        self.isActivatedAsServer = true
    }
    static func stopMesh() {
        if(self.isActivatedAsClient){
            return
        }
        self.runMesh(false)
        self.isActivatedAsServer = false
    }
    
    //MARK: Server Callback
    @objc static func meshEnabledProjectLoaded() {
        self.isActivatedAsClient = false
        self.clearConnectedIpAddress()
        self.bonjourPeerServer().start()
        self.isActivatedAsServer = true
    }
    
    //MARK: Basic
    static func runMesh(_ runOrNot: Bool) {
        DispatchQueue.main.async {
            SUYUtils.meshRun(runOrNot)
        }
    }
}
