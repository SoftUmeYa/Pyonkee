//
//  sqScratchIPhoneApplication.m
//  SqueakPureObjc
//
//  Created by John M McIntosh on 10-02-17.
//  Copyright 2010 Corporate Smalltalk Consulting Ltd. All rights reserved.
//

#import "sqScratchIPhoneApplication.h"
#import "SUYScratchAppDelegate.h"
#import "sqSqueakOSXSoundCoreAudio.h"
#import "SoundPlugin.h"
#import "sqSqueakIPhoneInfoPlistInterface.h"

extern ScratchIPhoneAppDelegate *gDelegateApp;
extern usqInt	gMaxHeapSize;

@implementation sqScratchIPhoneApplication

- (void) setupSoundLogic {
	self.soundInterfaceLogic = [sqSqueakOSXSoundCoreAudio new];
 	[(sqSqueakOSXSoundCoreAudio *) self.soundInterfaceLogic soundInitOverride];
	
	snd_Start(2644, 22050, 1, 0);
	char slience[10576];
	bzero(&slience, sizeof(slience));
	snd_PlaySamplesFromAtLength(2644,(usqInt * ) &slience,0);
	[self.soundInterfaceLogic snd_Stop];
}

- (void) doMemorySetup {
	gMaxHeapSize =  [(sqSqueakIPhoneInfoPlistInterface*) self.infoPlistInterfaceLogic memorySize];
	if (gMaxHeapSize <= 1){
		gMaxHeapSize =  50*1024*1024;
    }
    LgInfo(@"doMemorySetup gMaxHeapSize %d", gMaxHeapSize);
}

-(void)tearDown{
    [self.soundInterfaceLogic soundShutdown];
}
@end
