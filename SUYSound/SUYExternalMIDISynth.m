//
//  SUYExternalMIDISynth.m
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2015/06/05
//
//

#import "SUYExternalMIDISynth.h"

#import <MIKMIDI/MIKMIDI.h>
#import "SUYUtils.h"

@interface SUYExternalMIDISynth()

@property (nonatomic, strong) MIKMIDIDeviceManager *deviceManager;

@end


@implementation SUYExternalMIDISynth {
}

static SUYExternalMIDISynth *soleInstance;


#pragma mark - Actions

- (void) noteOn:(int) note velocity:(int)velocity channel:(int)channel
{
    MIKMIDINoteOnCommand *noteOn = [MIKMIDINoteOnCommand noteOnCommandWithNote:note velocity:velocity channel:channel timestamp:[NSDate date]];
    [self handleMIDIMessages: @[noteOn]];
}
- (void) noteOff:(int) note velocity:(int)velocity channel:(int)channel
{
    MIKMIDINoteOffCommand *noteOff = [MIKMIDINoteOffCommand noteOffCommandWithNote:note velocity:velocity channel:channel timestamp:[NSDate date]];
    [self handleMIDIMessages: @[noteOff]];
}
- (void) programChange:(int) progNum channel:(int)channel
{
    MIKMutableMIDIProgramChangeCommand *pchange = [[MIKMutableMIDIProgramChangeCommand alloc] init];
    pchange.programNumber = progNum;
    pchange.channel = channel;
    [self handleMIDIMessages: @[pchange]];
}
- (void) allSoundOff:(int)channel
{
    MIKMutableMIDIControlChangeCommand *cchange = [[MIKMutableMIDIControlChangeCommand alloc] init];
    cchange.controllerNumber = 120;
    cchange.controllerValue = 0;
    cchange.channel = channel;
    [self handleMIDIMessages: @[cchange]];
}

#pragma mark - Private

- (void) handleMIDIMessages: (NSArray<MIKMIDICommand *> *)commands
{
    /*
    for (MIKMIDIDestinationEndpoint *destination in self.deviceManager.virtualDestinations) {
        NSError *error = nil;
        LgInfo(@"destinations %d %@", destination.isVirtual, destination.displayName);
        BOOL result = [self.deviceManager sendCommands:commands toEndpoint:destination error:&error];
        if (!result) {
            LgWarn(@"Unable to send command %@ to endpoint %@: %@", (commands[0]), destination, error);
        }
    }
     */
    
    MIKMIDIDestinationEndpoint *destination = [self.deviceManager.virtualDestinations lastObject];
    NSError *error = nil;
    LgInfo(@"destinations %d %@", destination.isVirtual, destination.displayName);
    BOOL result = [self.deviceManager sendCommands:commands toEndpoint:destination error:&error];
    if (!result) {
        LgWarn(@"Unable to send command %@ to endpoint %@: %@", (commands[0]), destination, error);
    }
    
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"virtualDestinations"]) {
        
    }
}

#pragma mark - Properties

@synthesize deviceManager = _deviceManager;

- (void)setDeviceManager:(MIKMIDIDeviceManager *)deviceManager
{
    if (deviceManager != _deviceManager) {
        [_deviceManager removeObserver:self forKeyPath:@"virtualDestinations"];
        _deviceManager = deviceManager;
        [_deviceManager addObserver:self forKeyPath:@"virtualDestinations" options:NSKeyValueObservingOptionInitial context:NULL];
    }
}

- (MIKMIDIDeviceManager *)deviceManager
{
    if (!_deviceManager) {
        self.deviceManager = [MIKMIDIDeviceManager sharedDeviceManager];
    }
    return _deviceManager;
}



#pragma mark - Instance creation

+ (instancetype)soleInstance;
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        soleInstance = [(SUYExternalMIDISynth *)[super allocWithZone:NULL] init];
    });
    return soleInstance;
}

- (id)init
{
    if (self == soleInstance) return soleInstance;
    
    self = [super init];
    if (self) {
        //[self loadDefaultSoundFont];
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
