//
//  SUYLightSensor.m
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2015/06/05
//
//

#import "SUYMIDISynth.h"

#import "SUYInternalMIDISynth.h"
#import "SUYExternalMIDISynth.h"

#import "SUYScratchAppDelegate.h"
#import "sqSqueakIPhoneInfoPlistInterface.h"
#import "SUYUtils.h"

@interface SUYMIDISynth()
@property (nonatomic) SUYInternalMIDISynth* internal;
@property (nonatomic) SUYExternalMIDISynth* external;

@end


@implementation SUYMIDISynth {
    int lastProgNum;
    int lastProgNumChannel;
}

extern ScratchIPhoneAppDelegate *gDelegateApp;
static SUYMIDISynth *soleInstance;


#pragma mark - Actions

- (void) noteOn:(int) note velocity:(int)velocity channel:(int)channel
{
    if([self useExternal]){
        return [self.external noteOn:note velocity:velocity channel:channel];
    }
    [self.internal noteOn:note velocity:velocity channel:channel];
}
- (void) noteOff:(int) note velocity:(int)velocity channel:(int)channel
{
    if([self useExternal]){
        return [self.external noteOff:note velocity:velocity channel:channel];
    }
    [self.internal noteOff:note velocity:velocity channel:channel];
}
- (void) programChange:(int) progNum channel:(int)channel
{
    if([self useExternal]){
        return [self.external programChange:progNum channel:channel];
    }
    [self.internal  programChange:progNum channel:channel];
    lastProgNum = progNum;
    lastProgNumChannel = channel;
}
- (void) allSoundOff:(int)channel
{
    if([self useExternal]){
        return [self.external allSoundOff:channel];
    }
    [self.internal allSoundOff:channel];
}

#pragma mark - Testing
- (BOOL) useExternal
{
    return [(sqSqueakIPhoneInfoPlistInterface*) gDelegateApp.squeakApplication.infoPlistInterfaceLogic useVirtualMIDI];;
}

#pragma mark - Initialization
- (void) prepareDelegates
{
    self.internal = [SUYInternalMIDISynth newInstance];
    self.external = [SUYExternalMIDISynth soleInstance];
}

- (void) reset
{
    @synchronized(self){
        self.internal = [SUYInternalMIDISynth newInstance];
        [self.internal loadDefaultSoundFont];
        [self.internal programChange: lastProgNum channel: lastProgNumChannel]; //recover previous status
    }
}

#pragma mark - Instance creation

+ (instancetype)soleInstance;
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        soleInstance = [(SUYMIDISynth *)[super allocWithZone:NULL] init];
    });
    return soleInstance;
}

- (id)init
{
    if (self == soleInstance) return soleInstance;
    
    self = [super init];
    if (self) {
        [self prepareDelegates];
    }
    return self;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [self soleInstance];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}


@end
