//
//  MicrobitConstants.swift
//  Microbit
//
//  Copyright © 2021 Masashi Umezawa. All rights reserved.
//


import Foundation
import CoreBluetooth

// DEVICE INFORMATION
let DeviceInfoUUID = CBUUID(string:"180A")

struct ServiceUUIDs {
    static let AccelerometerServiceUUID = CBUUID(string:"E95D0753-251D-470A-A062-FA1922DFA9A8")
    static let MagnetometerServiceUUID = CBUUID(string: "E95DF2D8-251D-470A-A062-FA1922DFA9A8")
    static let ButtonServiceUUID = CBUUID(string: "E95D9882-251D-470A-A062-FA1922DFA9A8")
    static let IOpinServiceUUID = CBUUID( string:"E95D127B-251D-470A-A062-FA1922DFA9A8")
    static let LEDServiceUUID = CBUUID(string:"E95DD91D-251D-470A-A062-FA1922DFA9A8")
    static let EventServiceUUID = CBUUID(string: "E95D93AF-251D-470A-A062-FA1922DFA9A8")
    static let TempertureServiceUUID = CBUUID(string:"E95D6100-251D-470A-A062-FA1922DFA9A8")
    static let UARTServiceUUID = CBUUID(string:"6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    
    static let ALL: [CBUUID] = [AccelerometerServiceUUID, MagnetometerServiceUUID, ButtonServiceUUID, IOpinServiceUUID, LEDServiceUUID, EventServiceUUID, TempertureServiceUUID, UARTServiceUUID];
//    static let ALL: [CBUUID] = [CBUUID(string:"00001800-0000-1000-8000-00805F9B34FB")];
}
