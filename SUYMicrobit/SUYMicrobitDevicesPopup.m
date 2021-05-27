//
//  SUYMicrobitDevicesPopup.m
//  Scratch
//
//  Created by Masashi Umezawa on 2021/04/12.
//

#import "SUYMicrobitDevicesPopup.h"
#import <SDCAlertView/SDCAlertView.h>

#import "Pyonkee-Swift.h"

@interface SUYMicrobitDevicesPopup()

@property (nonatomic) SUYMicrobitAccessor *microbitAccessor;
@property (nonatomic) SDCAlertController *alert;
@property (nonatomic) NSMutableSet<SDCAlertAction*> *eachDeviceActions;

@property (nonatomic, readonly) NSDictionary<NSString*, Microbit *> * microbits;

@end

@implementation SUYMicrobitDevicesPopup

static SUYMicrobitDevicesPopup* _openedInstance;

#pragma mark Actions

+ (instancetype) openOn:(SUYMicrobitAccessor *)accessor {
    [self closeCurrent];
    SUYMicrobitDevicesPopup* inst = [[self alloc] init];
    inst.microbitAccessor = accessor;
    inst.eachDeviceActions = [[NSMutableSet alloc] init];
    [inst open];
    _openedInstance = inst;
    return inst;
}

+ (void) closeCurrent {
    if(_openedInstance) {
        [_openedInstance close];
        _openedInstance = NULL;
    }
}

- (void)open {
    if(self.alert){[self close];}
    if(self.microbitAccessor.isRunning == NO){
        [self.microbitAccessor start];
    }
    NSArray<Microbit*>* devs = self.mictobits.allValues;
    if(devs.count == 0) {
        [self openEmpty];
        return;
    }
    if(devs.count == 1 && (devs[0].isSelected && !devs[0].isConnected)) { //auto select but in vain
        [self openEmpty];
        return;
    }
    if(self.microbitAccessor.isConnected) {
        [self openWithConnectedDevice: [self.microbitAccessor currentMicrobit]];
        return;
    }
    [self openWithDevices:devs];
}

- (void) openEmpty {
    self.alert =  [SUYMicrobitUtils createAlertController: NSLocalizedString(@"Not found",nil)];
    [self addScanActionTo: self.alert];
    [self addStopActionTo: self.alert];
    [self addCloseActionTo: self.alert];
    [self.alert presentAnimated:NO completion:nil];
}

- (void) openWithConnectedDevice: (Microbit *) connectedMicrobit {
    NSString * title = @"";
    self.alert =  [SUYMicrobitUtils createAlertController:title];
    [self addActionFor:connectedMicrobit to: self.alert];
    [self addScanActionTo: self.alert];
    [self addStopActionTo: self.alert];
    [self addCloseActionTo: self.alert];
    [self.alert presentAnimated:NO completion:nil];
}

- (void) openWithDevices:(NSArray<Microbit *> *)vals{
    NSString * title = NSLocalizedString(@"Choose one",nil);
    self.alert =  [SUYMicrobitUtils createAlertController:title];
    for (Microbit* each in vals){
        [self addActionFor:each to: self.alert];
    }
    [self addScanActionTo: self.alert];
    [self addStopActionTo: self.alert];
    [self addCloseActionTo: self.alert];
    [self.alert presentAnimated:NO completion:nil];
}

- (void) close {
    [self.alert dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark Accessing

- (NSDictionary<NSString*, Microbit *> *) mictobits {
    return self.microbitAccessor.microbitSelector.microbits;
}

#pragma mark Private

- (void)addActionFor:(Microbit *)aMicrobit to:(SDCAlertController *)alertCon {
    
    UIColor* labelCol = [UIColor blackColor];
    if(@available(iOS 13.0, *)){
        labelCol = [UIColor labelColor];
    }
    
    NSMutableAttributedString *attrStr;
    attrStr = [[NSMutableAttributedString alloc] initWithString:aMicrobit.deviceName];
    [attrStr addAttribute:NSForegroundColorAttributeName
                    value:labelCol
                    range:NSMakeRange(0, [attrStr length])];
    
    SDCAlertAction* action = [self newActionAttributedTitled: attrStr style: SDCAlertActionStyleNormal handler:^(SDCAlertAction * ac) {
        BOOL notConnected = ! self.microbitAccessor.isConnected;
        if(notConnected && !((aMicrobit.isSelected && aMicrobit.isConnected))){
            for(SDCAlertAction *eachDeviceAction in self.eachDeviceActions){
                [self setLabelTo: eachDeviceAction checked: NO];
            }
            [self.microbitAccessor selectNamed: aMicrobit.deviceName];
            [self setLabelTo: ac checked: YES];
            [self.microbitAccessor reconnectOnDisconnect];
            for(SDCAlertAction *ea in self.alert.actions){
                ea.isEnabled = NO;
            }
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self close];
            });
        }
    }];
    
    BOOL isAvailable = (aMicrobit.isSelected && aMicrobit.isConnected);
    [self setLabelTo: action checked: isAvailable];
    
    if(self.microbitAccessor.isConnected){
        action.isEnabled = NO;
    }
        
    [alertCon addAction: action];
    [self.eachDeviceActions addObject:action];
}

- (void)addCloseActionTo:(SDCAlertController *)alertCon {
    SDCAlertAction* action = [self newActionTitled: NSLocalizedString(@"Close",nil) style: SDCAlertActionStyleNormal handler:^(SDCAlertAction * ac) {}];
    action.accessibilityIdentifier = @"close";
    [alertCon addAction: action];
}

- (void)addResetActionTo:(SDCAlertController *)alertCon {
    
    if (!self.microbitAccessor.isConnected) {return;}
    
    SDCAlertAction* action = [self newActionTitled: NSLocalizedString(@"Release the connection",nil) style: SDCAlertActionStyleNormal handler:^(SDCAlertAction * ac) {
        [self.microbitAccessor forgetLastSelection];
        if(self.microbitAccessor.isConnected){
            [self.microbitAccessor releaseCurrent];
        }
        [self close];
    }];
    action.accessibilityIdentifier = @"release";
    [alertCon addAction: action];
}

- (void)addScanActionTo:(SDCAlertController *)alertCon {
    SDCAlertAction* action = [self newActionTitled: NSLocalizedString(@"Scan other micro:bit peers",nil) style: SDCAlertActionStyleNormal handler:^(SDCAlertAction * ac) {
        __weak __typeof__(self) weakSelf = self;
        self.microbitAccessor.candidatesFoundHandler = ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf open];
            });
        };
        [self.microbitAccessor rescanWithAutoConnect: NO];
        [self close];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self open];
        });
    }];
    action.accessibilityIdentifier = @"scan";
    [alertCon addAction: action];
}

- (void)addStopActionTo:(SDCAlertController *)alertCon {
    SDCAlertAction* action = [self newActionTitled: NSLocalizedString(@"Stop interacting with micro:bit",nil) style: SDCAlertActionStyleDestructive handler:^(SDCAlertAction * ac) {
        if(self.microbitAccessor.isConnected){
            [self.microbitAccessor ignoreOnDisconnect];
            [self.microbitAccessor releaseCurrent];
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self.microbitAccessor stop];
        });
        [self close];
    }];
    action.accessibilityIdentifier = @"quit";
    [alertCon addAction: action];
}

- (void) setLabelTo:(SDCAlertAction*)action checked: (BOOL) checked{
    if(action.accessoryView == NULL){
        UILabel* label = [[UILabel alloc] init];
        [label setText: @"✓"];
        [label setFont: [UIFont systemFontOfSize:20.0f]];
        action.accessoryView = label;
    }
    UIColor* col = checked ? action.accessoryView.tintColor : [UIColor clearColor];
    action.accessibilityIdentifier = @"checked";
    ((UILabel*)action.accessoryView).textColor = col;
}

- (SDCAlertAction*)newActionAttributedTitled: (NSAttributedString*) title style: (enum SDCAlertActionStyle)style handler:(void (^ _Nullable)(SDCAlertAction * _Nonnull))handler {
    SDCAlertAction* action = [[SDCAlertAction alloc] initWithAttributedTitle: title style:style handler:handler];
    return action;
}

- (SDCAlertAction*)newActionTitled: (NSString*) title style: (enum SDCAlertActionStyle)style handler:(void (^ _Nullable)(SDCAlertAction * _Nonnull))handler {
    SDCAlertAction* action = [[SDCAlertAction alloc] initWithTitle: title style:style handler:handler];
    return action;
}


@end
