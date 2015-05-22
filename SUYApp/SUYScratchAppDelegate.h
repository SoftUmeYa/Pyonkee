//
//  SUYScratchAppDelegate.h
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2014/06/20
//  Modified, customized version of ScratchIPhoneAppDelegate.h
//
//  Originally Created by John M McIntosh on 10-02-14.
//  Copyright 2010 Corporate Smalltalk Consulting Ltd. All rights reserved.
//
//

#import "SqueakNoOGLIPhoneAppDelegate.h"
#import "SUYScratchPresentationSpace.h"
#import "SUYMailComposer.h"
#import	"squeakProxy.h"

@interface ScratchIPhoneAppDelegate : SqueakNoOGLIPhoneAppDelegate <UIAlertViewDelegate> {
	
}

@property (nonatomic, assign) BOOL squeakVMIsReady;
@property (nonatomic, retain) SqueakProxy *squeakProxy;
@property (nonatomic, retain) ScratchIPhonePresentationSpace* presentationSpace;

@property (nonatomic, retain) dispatch_queue_t defaultSerialQueue;
@property (nonatomic, retain) SUYMailComposer *mailComposer;

@property (nonatomic, copy) NSString* clickedResourcePathOnLaunch;

- (void) openDefaultProject;
- (void) openProject:(NSString*)projectPathName;
- (void) shoutGo;
- (void) stopAll;
- (void) exitPresentationMode;
- (void) commandKeyStateChanged:(BOOL)state;
- (void) shiftKeyStateChanged:(BOOL)state;
- (int)  getViewModeIndex;
- (void) setViewModeIndex:(int)mode;
- (void) setFontScaleIndex: (int)idx;
- (int)  getFontScaleIndex;
- (BOOL) scriptsAreRunning;
- (void) pickPhoto: (NSString *)filePath;
- (void) flushInputString: (NSString *)inputString;
- (void) restartVm;

- (void) enterRestart;
- (void) restartAfterDelay;
- (void) openCamera: (NSString *)clientMode;
- (void) openPhotoLibraryPicker: (NSString *)clientMode;
- (void) openHelp:(NSString *)url;

- (void) showWaitIndicator;
- (void) hideWaitIndicator;
- (void) mailProject: (NSString *)projectPath;
- (void) airDropProject: (NSString *)projectPath;
- (void) textMorphFocused: (NSString *)status;

- (void) bailWeAreBroken: (NSString *) oopsText;

- (BOOL) sizeOfMemoryIsTooLowForLargeImages;

- (UIScrollView *)scratchPlayView;
- (uint) squeakMemoryBytesLeft;
- (uint) squeakMaxHeapSize;
- (uint) restartCount;



@end
