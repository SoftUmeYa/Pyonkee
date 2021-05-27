//
//  SUYMicrobitAccessor.h
//  Scratch
//
//  Created by Masashi Umezawa 2021/03/28.
//

#import <Foundation/Foundation.h>
#import "Pyonkee-Swift.h"

NS_ASSUME_NONNULL_BEGIN

@interface SUYMicrobitAccessor : NSObject <MicrobitSelectorDelegate>

@property (nullable, nonatomic, strong) MicrobitSelector *microbitSelector;

@property (nonatomic, readonly, copy) NSSet<NSNumber *> * services;
@property (nonatomic, readonly, copy) NSString * uartMessage;
@property (nonatomic, readonly, copy) NSDictionary<NSNumber *, NSNumber *> * pinsValues;
@property (nonatomic, readonly) int16_t accX;
@property (nonatomic, readonly) int16_t accY;
@property (nonatomic, readonly) int16_t accZ;
@property (nonatomic, readonly) int16_t magX;
@property (nonatomic, readonly) int16_t magY;
@property (nonatomic, readonly) int16_t magZ;
@property (nonatomic, readonly) int16_t compassBearingValue;
@property (nonatomic, readonly) int8_t compassStateValue;
@property (nonatomic, readonly) int16_t temperatureValue;
@property (nonatomic, readonly, copy) NSDictionary<NSString *, NSNumber *> * buttonValues;
@property (nonatomic, readonly, copy) NSDictionary<NSString *, NSNumber *> * receivedEvent;

@property (nonatomic, readonly) int buttonAValue;
@property (nonatomic, readonly) int buttonBValue;

@property (nonatomic, readonly) int pin0Value;
@property (nonatomic, readonly) int pin1Value;
@property (nonatomic, readonly) int pin2Value;

@property (nonatomic, strong) NSMutableDictionary<NSString*, NSNumber*> * microbitCandidateNames;

@property (nullable, nonatomic, copy) void (^candidatesFoundHandler)(void);
@property (nullable, nonatomic, copy) void (^scanStoppedHandler)(void);

#pragma mark Testing
@property (nonatomic, readonly) BOOL isRunning;
@property (nonatomic, readonly) BOOL isConnected;
@property (nonatomic) BOOL shouldReconnect;

#pragma mark Actions

- (void) start;
- (void) stop;
- (void) selectNamed:(NSString * _Nonnull)localName;
- (void) releaseNamed:(NSString * _Nonnull)localName;
- (void) releaseCurrent;
- (void) forgetLastSelection;
- (void) rescanWithAutoConnect: (BOOL) shouldAutoConnect;
- (void) openPopup;
- (void) ignoreOnDisconnect;
- (void) reconnectOnDisconnect;

#pragma mark Actions - Microbit

- (void)disconnect;
- (void)ledTextWithMessage:(NSString * _Nonnull)message scrollRate:(int16_t)scrollRate;
- (void)ledWriteWithMatrix:(NSArray<NSNumber *> * _Nonnull)matrix;
- (void)ledSetStatesWithLedStateArray:(NSArray<NSNumber *> * _Nonnull)ledStateArray;
- (void)uartSendWithMessage:(NSString * _Nonnull)message;
- (void)pinsADConfigureWithAnalougePins:(NSDictionary<NSNumber *, NSNumber *> * _Nonnull)analougePins;
- (void)pinsRWConfigureWithReadPins:(NSDictionary<NSNumber *, NSNumber *> * _Nonnull)readPins;
- (void)pinsSendWithPinValues:(NSDictionary<NSNumber *, NSNumber *> * _Nonnull)pinValues;
- (void)accelerometerConfigureWithPeriod:(enum PeriodType)period;
- (void)magnetometerConfigureWithPeriod:(enum PeriodType)period;
- (void)magnetometerCalibrate;
- (void)temperatureConfigureWithPeriod:(uint16_t)period;
- (void)subscribeEventsWithEvents:(NSArray<NSNumber *> * _Nonnull)events;
- (void)triggerEventWithType:(uint16_t)eventType value:(uint16_t)eventValue;

- (void)pinToValue:(int) value at: (int) index;
- (void)pinToAnalog:(int) value at: (int) index;
- (void)pinToAnalogPeriod: (int) periodMicroseconds value: (int)value at: (int) index;
- (void)pinToRead:(int) value at: (int) index;

#pragma mark Accessing
-(int) runningMode;
-(Microbit*) currentMicrobit;
@end

NS_ASSUME_NONNULL_END
