//
//  SUYScratchAppDelegate.h
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2014/06/20
//  Modified, customized version of SUYScratchAppDelegate.h
//
//  Originally Created by John M McIntosh on 10-02-14.
//  Copyright 2010 Corporate Smalltalk Consulting Ltd. All rights reserved.
//
//

#import "SqueakNoOGLIPhoneAppDelegate.h"
#import "SUYScratchPresentationSpace.h"
#import "SUYMailComposer.h"
#import "SUYMicrobitAccessor.h"
#import	"squeakProxy.h"

#import "SUYScratchSceneDelegate.h"

#if (TARGET_OS_MACCATALYST)
#import "SUYDummySensorAccessor.h"
#else
#import "SUYSensorAccessor.h"
#endif

@interface SUYScratchAppDelegate : SqueakNoOGLIPhoneAppDelegate <UIMenuBuilder>{
	
}

@property (nonatomic) BOOL squeakVMIsReady;
@property (nonatomic, retain) SqueakProxy *squeakProxy;
@property (nonatomic, assign, readonly) ScratchIPhonePresentationSpace* presentationSpace;

@property (nonatomic, retain) dispatch_queue_t defaultSerialQueue;
@property (nonatomic, retain) SUYMailComposer *mailComposer;
@property (nonatomic, retain) SUYMicrobitAccessor *microbitAccessor;

#if (TARGET_OS_MACCATALYST)
@property (nonatomic, retain) SUYDummySensorAccessor *sensorAccessor;
#else
@property (nonatomic, retain) SUYSensorAccessor *sensorAccessor;
#endif

@property (nonatomic, copy) NSString* resourcePathOnLaunch;
@property (nonatomic) NSUInteger resourseLoadedCount;
@property (nonatomic, retain) SUYScratchSceneDelegate *currentSceneDelegate;

- (void) openDefaultProject;
- (void) openResource:(NSString*)projectPathName;
- (void) openImporting: (NSURL*) externalFileUrl;
- (void) shoutGo;
- (void) stopAll;
- (void) exitPresentationMode;
- (void) commandKeyStateChanged:(BOOL)state;
- (void) shiftKeyStateChanged:(BOOL)state;
- (int)  getViewModeIndex;
- (void) setViewModeIndex:(int)mode;
- (int)  getFontScaleIndex;
- (void) setFontScaleIndex: (int)idx;
- (int)  getDevelopmentModeIndex;
- (BOOL) isOnDevelopment;
- (BOOL) scriptsAreRunning;
- (void) pickPhoto: (NSString *)filePath;
- (void) flushInputString: (NSString *)inputString;
- (void) restartVm;
- (void) restoreDisplay;
- (void) restoreDisplayIfNeeded;
- (int) catalystMode;
- (float) osVersion;
- (BOOL) meshIsRunning;
- (void) meshJoin: (NSString *)inputString;
- (BOOL) meshJoined: (NSString *)inputString;
- (void) meshRun: (int) runOrNot;

- (void) enterRestart;
- (void) restartAfterDelay;
- (void) openCamera: (NSString *)clientMode;
- (void) openPhotoLibraryPicker: (NSString *)clientMode;
- (void) openHelp:(NSString *)url;

- (void) showWaitIndicator;
- (void) hideWaitIndicator;
- (void) mailProject: (NSString *)projectPath;
- (void) airDropProject: (NSString *)projectPath;
- (void) exportToCloud: (NSString *)resourcePath;
- (void) importFromCloud;
- (void) openMeshDialog;
- (void) textMorphFocused: (NSString *)status;
- (void) showCursor:(int)cursorCode;
- (void) hideCursor;

- (void) bailWeAreBroken: (NSString *) oopsText;

- (BOOL) sizeOfMemoryIsTooLowForLargeImages;

- (UIScrollView *)scratchPlayView;
- (uint) squeakMemoryBytesLeft;
- (uint) squeakMaxHeapSize;
- (uint) restartCount;

- (void)invalidateSceneDelegateCache;
- (void)becomeActive;
- (void)becomeBackground;

// Scene configuration
- (UISceneConfiguration *)application:(UIApplication *)application
configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession
                              options:(UISceneConnectionOptions *)options;

@end
