//
//  MicrobitSelector.swift
//  Microbit
//
//  Copyright © 2021 Masashi Umezawa. All rights reserved.
//

import Foundation
import CoreBluetooth

let MAX_SCAN_SECONDS = 60.0
let JUST_SCAN_SECONDS = 15.0
let UD_LAST_MB_UUID_KEY_AND_NAME = "SUY:MBPeripheralUuidAndName"

@objc open class MicrobitSelector: NSObject,CBCentralManagerDelegate,CBPeripheralDelegate {
    
    @objc public var delegate: MicrobitSelectorDelegate?
    
    var isRescanning = false
    
    var centralManager : CBCentralManager!
    @objc var microbits : Dictionary<String,Microbit> = [:]
    @objc var currentMicrobit : Microbit?
    
    // MARK: Initialization
    public override init() {
        super.init()
        self.initCentralManager()
    }
    
    open func initCentralManager(){
        let dispatchQueue = DispatchQueue(label: "com.suy.BluetoothCentralManager")
        centralManager = CBCentralManager(delegate: self, queue: dispatchQueue)
    }
    
    
    // MARK: CBCentralManagerDelegate
    open func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if (central.state == .poweredOn) {
            self.retrieveOrStartScan();
        } else {
            p("Bluetooth switched off or not initialized")
        }
    }
    
    open func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {

        if let serviceData = advertisementData[CBAdvertisementDataServiceDataKey] as? NSDictionary {
            serviceDataReceived(serviceData: serviceData, RSSI: RSSI)
        }
        
        let advDict = (advertisementData as NSDictionary)
        if let localName = advDict.object(forKey: CBAdvertisementDataLocalNameKey) as? String {
            p("Possible device detected: \(localName)")
            if(localName.hasPrefix("BBC micro:bit")){
                microbits[localName] = Microbit(localName, peripheral: peripheral)
            }
            
            p("-microbits-", microbits)
            delegate?.candidatesFound(Array(microbits.values))

        }
    }
    
    open func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if let mb = currentMicrobit {
            delegate?.connected(mb)
            mb.isConnected = true
            mb.discoverServices()
            storeMicrobitUuidOnConnected(mb)
        }
        
        if(self.connectedMicrobits().count >= 1){
            stopScan()
        }
    }
    
    open func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let mb = currentMicrobit {
            delegate?.disconnected(mb)
            mb.isConnected = false
            if(isRescanning){
                self.microbits = [:]
                self.startScan()
                isRescanning = false;
            }
        }
    }
    
    //MARK: Actions
    @objc open func selectNamed(_ localName:String){
        if(microbits.keys.contains(localName) == false) {return}
        currentMicrobit = microbits[localName]
        if let mb = currentMicrobit {
            mb.isSelected = true
            mb.prepare(self.centralManager)
            mb.delegate = MicrobitSensorValuesAccessor.shared
            p("currentMicrobit was selected!", localName)
        }
    }
    
    @objc open func releaseNamed(_ localName:String){
        if(microbits.keys.contains(localName) == false) {return}
        currentMicrobit = microbits[localName]
        if let mb = currentMicrobit {
            mb.isSelected = false
            mb.disconnect()
        }
    }
    
    @objc open func forgetLastSelection(){
        self.removeStoredMicrobitUuidAndName()
    }
    
    // MARK: Scanning
    
    @objc open func retrieveOrStartScan() {
        
        let storedUuidAndName = storedMicrobitUuidAndName()
    
        let uuidString = (storedUuidAndName?[0])
        let deviseName = (storedUuidAndName?[1])
        var peripherals: [CBPeripheral]
        
        if let uStr = uuidString {
            let uuid = UUID(uuidString:uStr)
            peripherals = centralManager.retrievePeripherals(withIdentifiers: [uuid!])
            if(trySelectOnceConnectedMicrobitIn(peripherals: peripherals, deviseName: deviseName!)){
                return
            }
        }
        
        peripherals = centralManager.retrieveConnectedPeripherals(withServices: ServiceUUIDs.ALL)
        if(peripherals.count > 0){
            let peripheralName = peripherals[Int.random(in: 0..<peripherals.count)].name
            if(trySelectOnceConnectedMicrobitIn(peripherals: peripherals, deviseName: peripheralName!)){
                return
            }
        }
        
        self.startScan()
    }
    
    @objc open func clearAndStartScan() {
        self.disconnectCurrentMicrobit()
        self.microbits = [:]
        startScan()
    }
    
    @objc open func clearAndStopScan() {
        self.disconnectCurrentMicrobit()
        self.microbits = [:]
        stopScan()
    }
    
    @objc open func disconnectCurrentMicrobit(){
        if let mb = currentMicrobit {
            mb.isSelected = false
            mb.disconnect()
        }
    }
    
    @objc open func startScan() {
        if(isRescanning == true) {return}
        isRescanning = true
        centralManager.scanForPeripherals(withServices: nil, options: nil)
        p("Start Scanning")
        DispatchQueue.main.asyncAfter(deadline: .now() + JUST_SCAN_SECONDS) { // avoid too many scans
            self.isRescanning = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + MAX_SCAN_SECONDS) {
            self.stopScan()
        }
    }
    @objc open func stopScan() {
        centralManager.stopScan()
        p("Stop scanning")
        delegate?.scanStopped(Array(microbits.values))
        isRescanning = false
    }
    
    // MARK: Testing
    @objc open func currentMicrobitIsSelected () -> Bool {
        return self.currentMicrobit != nil
    }
    
    @objc open func currentMicrobitIsSelectedAndConnected () -> Bool {
        return self.currentMicrobitIsSelected() && currentMicrobit?.isConnected == true && currentMicrobit?.delegate != nil
    }
    
    //MARK: Accessing
    @objc open func connectedMicrobits () -> [String:Microbit]{
        return microbits.filter { accoc in
            accoc.value.isConnected
        }
    }
    @objc open func selectedMicrobits () -> [String:Microbit]{
        return microbits.filter { accoc in
            accoc.value.isSelected
        }
    }
    
    func storeMicrobitUuidOnConnected(_ microbit: Microbit?) {
        let uuidString = microbit?.uuidString()
        let deviceName = microbit?.deviceName
        
        let userDefaults = UserDefaults.standard
        userDefaults.set([uuidString, deviceName], forKey: UD_LAST_MB_UUID_KEY_AND_NAME)
    }
    
    @objc open func storedMicrobitUuidAndName() -> [String]? {
        let userDefaults = UserDefaults.standard
        let uuidAndName = userDefaults.array(forKey: UD_LAST_MB_UUID_KEY_AND_NAME) as? [String]
        return uuidAndName
    }
    
    func removeStoredMicrobitUuidAndName(){
        let userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: UD_LAST_MB_UUID_KEY_AND_NAME)
    }
    
    func trySelectOnceConnectedMicrobitIn(peripherals: [CBPeripheral], deviseName: String) -> Bool {
        if(peripherals.count > 0){
            let retrievedPeripheral = peripherals[0]
            let peripheralName = retrievedPeripheral.name
            if(deviseName == peripheralName){
                let mb = Microbit(deviseName, peripheral: retrievedPeripheral)
                microbits[deviseName] = mb
                selectNamed(deviseName)
                return true
            }
        }
        return false
    }
    
    //MARK: Handling service data
    func serviceDataReceived(serviceData:NSDictionary,RSSI:NSNumber) {
        for data in serviceData {
            let id = "\(data.key)"
            let dataBytes = data.value as? Data ?? Data(_:[0x00])
            var dataArray:[UInt8] = Array(repeating:0,count:dataBytes.count)
            dataBytes.copyBytes(to: &dataArray,count:dataArray.count)
            p("Service data: \(dataBytes.map { String(format: "%02x", $0) }.joined()),RSSI: \(RSSI)")
            if id == "FEAA" {
                dataBytes.withUnsafeBytes {(ptr: UnsafePointer<UInt8>) in
                    let type = Int(dataBytes[0])
                    var url = " "
                    var namespace:Int64 = 0
                    var instance:Int32 = 0
                    if type == 0 {
                        var rawPtr = UnsafeRawPointer(ptr + 4)
                        let typedPointer4 = rawPtr.bindMemory(to: Int64.self, capacity: 1)
                        namespace = Int64(bigEndian:typedPointer4.pointee)
                        rawPtr = UnsafeRawPointer(ptr + 14)
                        let typedPointer14 = rawPtr.bindMemory(to: Int32.self, capacity: 1)
                        instance = Int32(bigEndian:typedPointer14.pointee)
                    } else {
                        let text = dataBytes.subdata(in: 2..<dataBytes.count)
                        url = String(data: text, encoding: String.Encoding.utf8) ?? "Error"
                    }
                    let rssi = Int(truncating:RSSI)
                    p("Advertisement data - url: \(url), namespace: \(namespace), instance: \(instance), RSSI: \(rssi)")
                    delegate?.advertisementDataReceived(url: url, namespace: namespace, instance: instance, RSSI: rssi)
                }
            }
        }
    }
    
}
