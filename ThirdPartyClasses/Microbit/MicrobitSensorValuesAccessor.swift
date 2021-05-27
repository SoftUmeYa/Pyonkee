//
//  MicrobitSensorValuesAccessor.swift
//  Microbit
//
//  Created by Masashi Umezawa on 2021/03/20.
//  Copyright © 2021 Masashi Umezawa. All rights reserved.
//

import Foundation

@objc class MicrobitSensorValuesAccessor:  NSObject, MicrobitReadValuesDelegate {
    @objc static let shared = MicrobitSensorValuesAccessor()
    private override init() {}
    
    @objc private(set) var services:Set<Int> = Set()
    @objc private(set) var uartMessage:String = ""
    @objc private(set) var pinsValues:[UInt8:UInt8] = [:]
    @objc private(set) var accX:Int16 = 0
    @objc private(set) var accY:Int16 = 0
    @objc private(set) var accZ:Int16 = 0
    @objc private(set) var magX:Int16 = 0
    @objc private(set) var magY:Int16 = 0
    @objc private(set) var magZ:Int16 = 0
    @objc private(set) var compassBearingValue:Int16 = 0
    @objc private(set) var compassStateValue:Int8 = 0
    @objc private(set) var temperatureValue:Int16 = 0
    @objc private(set) var buttonValues:[String:Int] = [:]
    @objc private(set) var receivedEvent:[String:Int16] = [:]
    
    
    func serviceAvailable(service:ServiceType) {
        services.insert(service.rawValue)
        p("serviceAvailable",service.rawValue,services)
    }
    
    
    func logUpdated(_ log:[String]) {p(log)}
    func advertisementDataReceived(url:String,namespace:Int64,instance:Int32,RSSI:Int) {}
    
    func uartReceived(message:String) {
        p("uartReceived",message)
        uartMessage = message
    }
    
    func pinsReceived(pins:[UInt8:UInt8]) {
        p("pinsReceived",pins)
        pinsValues = pins
    }
    
    func buttonPressed(button:String,action:MicrobitButtonEventType) {
        p("buttonPressed",button,action)
        buttonValues[button] = action.rawValue
    }
    
    func accelerometerReceived(x:Int16,y:Int16,z:Int16) {
        p("accelerometerReceived", x,y,z)
        accX = x
        accY = y
        accZ = z
    }
    
    func magnetometerReceived(x:Int16,y:Int16,z:Int16) {
        p("magnetometerReceived",x,y,z)
        magX = x
        magY = y
        magZ = z
    }
    func compassBearingReceived(bearing:Int16) {
        p("compassBearingReceived", bearing)
        compassBearingValue = bearing
    }
    func compassCalibrationReceived(state:Int8) {
        p("compassCalibrationReceived", state)
        compassStateValue = state
    }
    
    func eventReceived(type:Int16,value:Int16) {
        p("eventReceived",type,value)
        receivedEvent = [
            "value": type,
            "type": value
        ]
    }
    
    func temperatureReceived(value:Int16) {
        p("temperatureReceived",value)
        temperatureValue = value
    }
}
