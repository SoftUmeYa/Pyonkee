//
//  MicrobitEnums.swift
//
//  Microbit
//  Copyright © 2021 Masashi Umezawa. All rights reserved.
//

import Foundation

/**
 Services available from a micro:bit peripheral
*/
@objc public enum ServiceType:Int {
    case Event
    case DeviceInfo
    case Accelerometer
    case Magnetometer
    case Button
    case IOPin
    case LED
    case Temperature
    case UART
}
/**
 Button states enumerated by the micro:bit button service
*/
@objc public enum MicrobitButtonEventType:Int {
    case Up
    case Down
    case Long
    case Invalid
}
/**
 Magnetometer and Accelerometer reporting periods in milliseconds
*/
@objc public enum PeriodType:Int {
    case p1 = 1
    case p2 = 2
    case p5 = 5
    case p10 = 10
    case p20 = 20
    case p80 = 80
    case p160 = 160
    case p640 = 640
}
/**
 Available events that can be detected by the micro:bit using control.onEvent
 https://github.com/lancaster-university/microbit-dal/blob/master/inc/bluetooth/MESEvents.h
*/
@objc public enum MicrobitEventType:Int {
    case REMOTE_CONTROL_ID = 1001
    case CAMERA_ID = 1002
    case ALERTS_ID = 1004
    
    case SIGNAL_STRENGTH_ID = 1101
    case DEVICE_INFO_ID = 1103
    case DPAD_CONTROLLER_ID = 1104
    
    case BROADCAST_GENERAL_ID = 2000
}

@objc public enum RemoteControlEventType:Int {
    case REMOTE_CONTROL_EVT_PLAY = 1
    case REMOTE_CONTROL_EVT_PAUSE = 2
    case REMOTE_CONTROL_EVT_STOP = 3
    case REMOTE_CONTROL_EVT_NEXTTRACK = 4
    case REMOTE_CONTROL_EVT_PREVTRACK = 5
    case REMOTE_CONTROL_EVT_FORWARD = 6
    case REMOTE_CONTROL_EVT_REWIND = 7
    case REMOTE_CONTROL_EVT_VOLUMEUP = 8
    case REMOTE_CONTROL_EVT_VOLUMEDOWN = 9
}

@objc public enum CameraEventType:Int {
    case CAMERA_EVT_LAUNCH_PHOTO_MODE = 1
    case CAMERA_EVT_LAUNCH_VIDEO_MODE = 2
    case CAMERA_EVT_TAKE_PHOTO =  3
    case CAMERA_EVT_START_VIDEO_CAPTURE = 4
    case CAMERA_EVT_STOP_VIDEO_CAPTURE = 5
    case CAMERA_EVT_STOP_PHOTO_MODE =   6
    case CAMERA_EVT_STOP_VIDEO_MODE =   7
    case CAMERA_EVT_TOGGLE_FRONT_REAR = 8
}

@objc public enum AlertEventType:Int {
    case ALERT_EVT_DISPLAY_TOAST = 1
    case ALERT_EVT_VIBRATE  = 2
    case ALERT_EVT_PLAY_SOUND = 3
    case ALERT_EVT_PLAY_RINGTONE = 4
    case ALERT_EVT_FIND_MY_PHONE = 5
    case ALERT_EVT_ALARM1 = 6
    case ALERT_EVT_ALARM2 =    7
    case ALERT_EVT_ALARM3 =    8
    case ALERT_EVT_ALARM4 =    9
    case ALERT_EVT_ALARM5 =    10
    case ALERT_EVT_ALARM6 =    11
}


@objc public enum SignalStrengthType:Int {
    case SIGNAL_STRENGTH_EVT_NO_BAR = 1
    case SIGNAL_STRENGTH_EVT_ONE_BAR = 2
    case SIGNAL_STRENGTH_EVT_TWO_BAR = 3
    case SIGNAL_STRENGTH_EVT_THREE_BAR = 4
    case SIGNAL_STRENGTH_EVT_FOUR_BAR = 5
}

@objc public enum DeviceInfoType:Int {
    case DEVICE_ORIENTATION_LANDSCAPE = 1
    case DEVICE_ORIENTATION_PORTRAIT = 2
    case DEVICE_GESTURE_NONE = 3
    case DEVICE_GESTURE_DEVICE_SHAKEN = 4
    case DEVICE_DISPLAY_OFF =  5
    case DEVICE_DISPLAY_ON =   6
    case DEVICE_INCOMING_CALL = 7
    case DEVICE_INCOMING_MESSAGE = 8
}

@objc public enum DPADType:Int {
    case DPAD_BUTTON_A_DOWN = 1
    case DPAD_BUTTON_A_UP =   2
    case DPAD_BUTTON_B_DOWN = 3
    case DPAD_BUTTON_B_UP =   4
    case DPAD_BUTTON_C_DOWN = 5
    case DPAD_BUTTON_C_UP =   6
    case DPAD_BUTTON_D_DOWN = 7
    case DPAD_BUTTON_D_UP =   8
    case DPAD_BUTTON_1_DOWN = 9
    case DPAD_BUTTON_1_UP =   10
    case DPAD_BUTTON_2_DOWN = 11
    case DPAD_BUTTON_2_UP =   12
    case DPAD_BUTTON_3_DOWN = 13
    case DPAD_BUTTON_3_UP =   14
    case DPAD_BUTTON_4_DOWN = 15
    case DPAD_BUTTON_4_UP =   16
}
