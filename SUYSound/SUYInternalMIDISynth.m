//
//  SUYInternalMIDISynth.m
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2017/03/24
//
//

#import "SUYInternalMIDISynth.h"

#import <MIKMIDI/MIKMIDI.h>
#import "SUYUtils.h"

@interface SUYInternalMIDISynth()


@end


@implementation SUYInternalMIDISynth {
    BOOL soundFontLoaded;
}

static SUYInternalMIDISynth *soleInstance;
static NSString *const kDefaultSountFont = @"TimGM6mb";


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



#pragma mark - Loading
- (void)asyncLoadDefaultSoundFont{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self loadDefaultSoundFont];
    });
}

- (void)loadDefaultSoundFont{
    NSURL *soundfont = [[NSBundle mainBundle] URLForResource:kDefaultSountFont withExtension:@"sf2"];
    LgInfo(@"Soundfont  %@", soundfont);
    NSError *error = nil;
    if (![self loadSoundfontFromFileAtURL:soundfont error:&error]) {
        LgError(@"Error loading soundfont. %@", error);
    } else {
        soundFontLoaded = YES;
    }
}

- (BOOL)loadSoundfontFromFileAtURL:(NSURL *)fileURL error:(NSError **)error{
    error = error ? error : &(NSError *__autoreleasing){ nil };
    OSStatus err = noErr;
    
    errno = 0;
    
    err = AudioUnitSetProperty(self.instrumentUnit,
                               kMusicDeviceProperty_SoundBankURL,
                               kAudioUnitScope_Global,
                               0,
                               &fileURL,
                               sizeof(fileURL));
    UInt32 enabled = 1;
    AudioUnitSetProperty(self.instrumentUnit,
                         kAUMIDISynthProperty_EnablePreload, kAudioUnitScope_Global, 0,
                         &enabled, sizeof(enabled));
    
    UInt32 pcCommand = 0xC0 | 0;
    for(int i = 0; i < 128; i++){
        MusicDeviceMIDIEvent(self.instrumentUnit, pcCommand, i, 0, 0);
    }
    UInt32 disabled = 0;
    AudioUnitSetProperty(self.instrumentUnit,
                         kAUMIDISynthProperty_EnablePreload, kAudioUnitScope_Global, 0,
                         &disabled, sizeof(disabled));
    
    if (err != noErr) {
        *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil];
        return NO;
    }
    return YES;
}

#pragma mark - Instruments

+ (AudioComponentDescription)appleSynthComponentDescription
{
    AudioComponentDescription instrumentcd = (AudioComponentDescription){0};
    instrumentcd.componentManufacturer = kAudioUnitManufacturer_Apple;
    instrumentcd.componentType = kAudioUnitType_MusicDevice;
    instrumentcd.componentSubType = kAudioUnitSubType_MIDISynth;
    return instrumentcd;
}


#pragma mark - Instance creation

+ (instancetype)soleInstance;
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        soleInstance = [(SUYInternalMIDISynth *)[super allocWithZone:NULL] init];
    });
    return soleInstance;
}

- (id)init
{
    if (self == soleInstance) return soleInstance;
    
    self = [super init];
    if (self) {
        soundFontLoaded = NO;
        [self asyncLoadDefaultSoundFont];
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
