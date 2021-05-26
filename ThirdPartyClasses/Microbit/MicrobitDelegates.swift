//
//  MicrobitDelegates.swift
//  Microbit
//
//  Copyright © 2021 Masashi Umezawa. All rights reserved.
//

import Foundation

@objc public protocol MicrobitSelectorDelegate {
    func candidatesFound(_ microbits:[Microbit])
    func connected(_ microbit:Microbit)
    func disconnected(_ microbit:Microbit)
    func scanStopped(_ microbits:[Microbit])
    func advertisementDataReceived(url:String,namespace:Int64,instance:Int32,RSSI:Int)
}

public protocol MicrobitReadValuesDelegate {
    func logUpdated(_ log:String)
    func serviceAvailable(service:ServiceType)
    func uartReceived(message:String)
    func pinsReceived(pins:[UInt8:UInt8])
    func buttonPressed(button:String,action:MicrobitButtonEventType)
    func accelerometerReceived(x:Int16,y:Int16,z:Int16)
    func magnetometerReceived(x:Int16,y:Int16,z:Int16)
    func compassBearingReceived(bearing:Int16)
    func compassCalibrationReceived(state:Int8)
    func eventReceived(type:Int16,value:Int16)
    func temperatureReceived(value:Int16)
}
extension MicrobitReadValuesDelegate {
    func logUpdated(_ log:String) {p(log)}
    func serviceAvailable(service:ServiceType) {}
    func uartReceived(message:String) {}
    func pinsReceived(pins:[UInt8:UInt8]) {}
    func buttonPressed(button:String,action:MicrobitButtonEventType) {}
    func accelerometerReceived(x:Int16,y:Int16,z:Int16) {}
    func magnetometerReceived(x:Int16,y:Int16,z:Int16) {}
    func compassBearingReceived(bearing:Int16) {}
    func compassCalibrationReceived(state:Int8) {}
    func eventReceived(type:Int16,value:Int16) {}
    func temperatureReceived(value:Int16) {}
}
