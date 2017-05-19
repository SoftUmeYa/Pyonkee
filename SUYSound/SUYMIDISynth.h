//
//  SUYMIDISynth.h
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2017/03/17
//
//



@interface SUYMIDISynth: NSObject

+ (SUYMIDISynth*) soleInstance;

- (void) noteOn:(int) note velocity:(int)velocity channel:(int)channel;
- (void) noteOff:(int) note velocity:(int)velocity channel:(int)channel;
- (void) programChange:(int) progNum channel:(int)channel;
- (void) allSoundOff:(int)channel;

- (void) prepareDelegates;

@end
