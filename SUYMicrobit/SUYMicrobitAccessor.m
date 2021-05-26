//
//  SUYMicrobitAccessor.m
//  Scratch
//
//  Created by Masashi Umezawa on 2021/03/28.
//

#import "SUYMicrobitAccessor.h"
#import "Pyonkee-Swift.h"
#import "SUYUtils.h"
#import "SUYMicrobitDevicesPopup.h"

@interface SUYMicrobitAccessor()

@property (nonatomic) Microbit *currentMicrobit;

@property (nonatomic) NSMutableDictionary<NSNumber *, NSNumber *> * pinsAnalogConfig;
@property (nonatomic) NSMutableDictionary<NSNumber *, NSNumber *> * pinsReadConfig;

@end

@implementation SUYMicrobitAccessor

#pragma mark Initialization

- (void) initPinsAnalogConfig {
    self.pinsAnalogConfig = [@{} mutableCopy];
}
- (void) initPinsReadConfig {
    self.pinsReadConfig = [@{} mutableCopy];
}
- (void) preparePinsAnalogConfigAt: (int) index {
    self.pinsAnalogConfig[@(index)] = @(NO);
}
- (void) preparePinsReadConfigAt: (int) index {
    self.pinsReadConfig[@(index)] = @(NO);
}

#pragma mark Actions

- (void) start
{
    if (self.isRunning) {[self stop];}
    self.microbitSelector = [[MicrobitSelector alloc] init];
    self.microbitSelector.delegate = self;
    [self initPinsAnalogConfig];
    [self initPinsReadConfig];
    [self reconnectOnDisconnect];
    if([self.microbitSelector storedMicrobitUuidAndName]){
        [self showToastAfterTryConnecting];
    } else {
        [self deferOpenPopup];
    }
}

- (void) tryAutoConnect {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self.microbitSelector retrieveOrStartScan];
    });
}

- (void) stop
{
    if(self.isConnected){
        [self releaseCurrent];
    }
    [self.microbitSelector stopScan];
    [self initPinsAnalogConfig];
    [self initPinsReadConfig];
    self.microbitSelector = NULL;
}

- (void) selectNamed:(NSString * _Nonnull)localName
{
    LgInfo(@"MB:select: %@", localName);
    [self.microbitSelector selectNamed:localName];
}
- (void) releaseNamed:(NSString * _Nonnull)localName
{
    LgInfo(@"MB:release: %@", localName);
    [self.microbitSelector releaseNamed:localName];
}
- (void) releaseCurrent
{
    [self releaseNamed: self.currentMicrobit.deviceName];
}


- (void) forgetLastSelection
{
    [self.microbitSelector forgetLastSelection];
}

- (void) rescanWithAutoConnect: (BOOL) shouldAutoConnect
{
    if(!shouldAutoConnect){
        [self ignoreOnDisconnect];
        [self.microbitSelector clearAndStartScan];
    } else {
        [self reconnectOnDisconnect];
        [self.microbitSelector disconnectCurrentMicrobit];
    }
    
}

-  (void) ignoreOnDisconnect{
    self.shouldReconnect = NO;
}

-  (void) reconnectOnDisconnect{
    self.shouldReconnect = YES;
}



#pragma mark UI - notification

- (void) openPopup
{
    dispatch_async(dispatch_get_main_queue(),^{
        [SUYMicrobitDevicesPopup openOn: self];
    });
}
- (void) closePopup
{
    dispatch_async(dispatch_get_main_queue(),^{
        [SUYMicrobitDevicesPopup closeCurrent];
    });
}

- (void) deferOpenPopup {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self openPopup];
    });
}

- (void) showToastAfterTryConnecting
{
    [self tryAutoConnect];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if(self.isConnected && self.currentMicrobit){
            [self showConnectedToast: self.currentMicrobit];
        } else {
            [self showNotFoundToast];
            [self.microbitSelector forgetLastSelection];
            [self.microbitSelector clearAndStopScan];
        }
    });
}


- (void) showToast:(NSString*) message image:(UIImage*) image on: (Microbit*) mb {
    [self closePopup];
    NSString* title = (mb) ? mb.deviceName : @"micro:bit";
    dispatch_async(dispatch_get_main_queue(),^{
        [SUYUtils showToast:message image:image title: title];
    });
}

- (void) showConnectedToast: (Microbit * _Nonnull) microbit {
    UIImage *image = [UIImage imageNamed:@"check-flat"];
    [self showToast: NSLocalizedString(@"Connected",nil) image: image on: microbit];
}

- (void) showDisconnectedToast: (Microbit * _Nonnull) microbit {
    UIImage *image = [UIImage imageNamed:@"close-flat"];
    [self showToast: NSLocalizedString(@"Disconnected",nil) image: image on: microbit];
}

- (void) showNotFoundToast {
    UIImage *image = [UIImage imageNamed:@"close-flat"];
    [self showToast: NSLocalizedString(@"Not found",nil) image: image on: NULL];
}

#pragma mark Actions - Microbit

- (void)disconnect
{
    [self.currentMicrobit disconnect];
}

- (void)ledTextWithMessage:(NSString * _Nonnull)message scrollRate:(int16_t)scrollRate
{
    [self.currentMicrobit ledTextWithMessage:message scrollRate:scrollRate];
}

- (void)ledWriteWithMatrix:(NSArray<NSNumber *> * _Nonnull)matrix
{
    [self.currentMicrobit ledWriteWithMatrix:matrix];
}

- (void)ledSetStatesWithLedStateArray:(NSArray<NSNumber *> * _Nonnull)ledStateArray
{
    [self.currentMicrobit ledSetStatesWithLedStateArray:ledStateArray];
}
- (void)uartSendWithMessage:(NSString * _Nonnull)message
{
    NSString* shortenMessage = [self truncateMessageForUart: message];
    [self.currentMicrobit uartSendWithMessage:shortenMessage];
}
- (void)pinsADConfigureWithAnalougePins:(NSDictionary<NSNumber *, NSNumber *> * _Nonnull)analougePins
{
    [self.currentMicrobit pinsADConfigureWithAnalougePins:analougePins];
}
- (void)pinsRWConfigureWithReadPins:(NSDictionary<NSNumber *, NSNumber *> * _Nonnull)readPins
{
    [self.currentMicrobit pinsRWConfigureWithReadPins:readPins];
}
- (void)pinsSendWithPinValues:(NSDictionary<NSNumber *, NSNumber *> * _Nonnull)pinValues
{
    [self.currentMicrobit pinsSendWithPinValues:pinValues];
}
- (void)accelerometerConfigureWithPeriod:(enum PeriodType)period
{
    [self.currentMicrobit accelerometerConfigureWithPeriod:period];
}
- (void)magnetometerConfigureWithPeriod:(enum PeriodType)period
{
    [self.currentMicrobit magnetometerConfigureWithPeriod:period];
}
- (void)magnetometerCalibrate
{
    [self.currentMicrobit magnetometerCalibrate];
}
- (void)temperatureConfigureWithPeriod:(uint16_t)period
{
    [self.currentMicrobit temperatureConfigureWithPeriod:period];
}
- (void)subscribeEventsWithEvents:(NSArray<NSNumber *> * _Nonnull)events
{
    [self.currentMicrobit subscribeEventsWithEvents:events];
}
- (void)triggerEventWithType:(uint16_t)eventType value:(uint16_t)eventValue
{
    [self.currentMicrobit triggerEventWithType:eventType value:eventValue];
}

#pragma mark Convenient - Pins

- (void)pinToValue:(int) value at: (int) index {
    NSNumber* readConfigValue = self.pinsReadConfig[@(index)];
    if(readConfigValue == NULL){
        [self preparePinsReadConfigAt: index];
        [self pinsRWConfigureWithReadPins: [NSDictionary dictionaryWithDictionary:self.pinsReadConfig]];
    }
    if(readConfigValue.boolValue == YES) {
        [self pinToRead: NO at: index];
    }
    int newValue = ([self isPinAnalogAt: index]) ? (value >> 2) : value;
    NSDictionary<NSNumber *, NSNumber *> * pinValues = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:newValue] forKey:[NSNumber numberWithInt:index]];
    [self pinsSendWithPinValues: pinValues];
}
- (void)pinToAnalog:(int) value at: (int) index {
    NSNumber* val = self.pinsAnalogConfig[@(index)];
    if(val == NULL){
        [self preparePinsAnalogConfigAt: index];
    }
    int flagValue = (value == 0) ? 0 : 1;
    self.pinsAnalogConfig[@(index)] = @(flagValue);
    [self pinsADConfigureWithAnalougePins: [NSDictionary dictionaryWithDictionary:self.pinsAnalogConfig]];
    
}
- (void)pinToRead:(int) value at: (int) index {
    NSNumber* val = self.pinsReadConfig[@(index)];
    if(val == NULL){
        [self preparePinsReadConfigAt: index];
    }
    int flagValue = (value == 0) ? 0 : 1;
    self.pinsReadConfig[@(index)] = @(flagValue);
    [self pinsRWConfigureWithReadPins: [NSDictionary dictionaryWithDictionary:self.pinsReadConfig]];
}

- (void)pinToAnalogPeriod: (int)periodMicroseconds value: (int)value at: (int)pinIndex {
    UInt8 index = [NSNumber numberWithInt: pinIndex].unsignedIntValue;
    UInt16 rawVal = [NSNumber numberWithInt: value].unsignedIntValue;
    UInt16 val = ([self isPinAnalogAt: index]) ? (rawVal >> 2) : rawVal;
    UInt32 microseconds = [NSNumber numberWithInt: periodMicroseconds].unsignedIntValue;
    [self.currentMicrobit pinPwmConfigureWithPin:index value:val period:microseconds];
}

#pragma mark Accessing - Microbit

- (MicrobitSensorValuesAccessor*) valuesAccessor
{
    return [MicrobitSensorValuesAccessor shared];
}

-(NSSet<NSNumber *>*) services
{
    return self.valuesAccessor.services;
}
-(NSString*) uartMessage
{
    NSString* str = self.valuesAccessor.uartMessage;
    if([str length] == 0) { return @"";}
    return str;
}
-(NSDictionary<NSNumber *, NSNumber *> *) pinsValues
{
    return self.valuesAccessor.pinsValues;
}

-(int16_t) accX
{
    return self.valuesAccessor.accX;
}
-(int16_t) accY
{
    return self.valuesAccessor.accY;
}
-(int16_t) accZ
{
    return self.valuesAccessor.accZ;
}

-(int16_t) magX
{
    return self.valuesAccessor.magX;
}
-(int16_t) magY
{
    return self.valuesAccessor.magY;
}
-(int16_t) magZ
{
    return self.valuesAccessor.magZ;
}

-(int16_t) compassBearingValue
{
    return self.valuesAccessor.compassBearingValue;
}
-(int8_t) compassStateValue
{
    return self.valuesAccessor.compassStateValue;
}
-(int16_t) temperatureValue
{
    return self.valuesAccessor.temperatureValue;
}

-(NSDictionary<NSString *, NSNumber *> *) buttonValues
{
    return self.valuesAccessor.buttonValues;
}
-(NSDictionary<NSString *, NSNumber *> *) receivedEvent
{
    return self.valuesAccessor.receivedEvent;
}

- (int) buttonAValue
{
    NSNumber * value = (NSNumber*)[self.buttonValues objectForKey:@"A"];
    if(value == NULL) {return 0;}
    return value.intValue;
}
- (int) buttonBValue
{
    NSNumber * value = (NSNumber*)[self.buttonValues objectForKey:@"B"];
    if(value == NULL) {return 0;}
    return value.intValue;
}

- (int) pin0Value
{
    return [self pinValueAt: 0];
}
- (int) pin1Value
{
    return [self pinValueAt: 1];
}
- (int) pin2Value
{
    return [self pinValueAt: 2];
}

- (int) pinValueAt:(int)index{
    NSNumber * value = self.pinsValues[@(index)];
    uint8_t val = value.unsignedIntValue;
    if([self isPinAnalogAt: index]){
        return val << 2;
    }
    return val;
}

#pragma mark Testing

- (BOOL) isRunning
{
    return self.microbitSelector != NULL;
}
- (BOOL) isConnected
{
    return self.microbitSelector.currentMicrobitIsSelectedAndConnected;
}

- (BOOL) isPinAnalogAt: (int)index {
    NSNumber * isAnalogValue = self.pinsAnalogConfig[@(index)];
    return isAnalogValue.boolValue;
}

#pragma mark Accessing
-(int) runningMode
{
    return (int)self.isRunning;
}
-(Microbit*) currentMicrobit
{
    return self.microbitSelector.currentMicrobit;
}

#pragma mark MicrobitSelectorDelegate

- (void) candidatesFound:(NSArray<Microbit *> *)microbits{
    self.microbitCandidateNames = [[NSMutableDictionary alloc] init];
    for (Microbit *mb in microbits) {
        [self.microbitCandidateNames setObject: [NSNumber numberWithBool: mb.isSelected] forKey: mb.deviceName];
    }
    if(self.candidatesFoundHandler){
        self.candidatesFoundHandler();
        self.candidatesFoundHandler = NULL;
    }
}

- (void) scanStopped:(NSArray<Microbit *> *)microbits{
    if(self.scanStoppedHandler){
        self.scanStoppedHandler();
        self.scanStoppedHandler = NULL;
    }
}

- (void) connected:(Microbit *)microbit{
    self.currentMicrobit = microbit;
}

- (void) disconnected:(Microbit *)microbit{
    if(microbit.isConnected == NO) {
        return;
    }
    [self showDisconnectedToast: microbit];
    self.currentMicrobit = NULL;
    if(self.shouldReconnect && [self isRunning]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self rescanWithAutoConnect: YES];
            [self showToastAfterTryConnecting];
        });
    }
}

- (void) advertisementDataReceivedWithUrl:(NSString *)url namespace:(int64_t)namespace_ instance:(int32_t)instance RSSI:(NSInteger)RSSI{
   
}


#pragma mark Private
- (NSString*) truncateMessageForUart: (NSString*) originalString {
    NSRange stringRange = {0, MIN([originalString length], 20)};
    stringRange = [originalString rangeOfComposedCharacterSequencesForRange:stringRange];
    return [originalString substringWithRange:stringRange];
}

@end
