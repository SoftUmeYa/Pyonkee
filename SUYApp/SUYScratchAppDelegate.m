//
//  SUYScratchAppDelegate.m
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2014/06/20
//  Modified, customized version of ScratchIPhoneAppDelegate.m
//
//  Originally Created by John M McIntosh on 10-02-14.
//  Copyright 2010 Corporate Smalltalk Consulting Ltd. All rights reserved.
//
//

#import "SUYScratchAppDelegate.h"
#import "SUYNavigationController.h"
#import "SUYLauncherViewController.h"
#import "sqSqueakIPhoneInfoPlistInterface.h"
#import "SUYScratchPresentationSpace.h"
#import "sqScratchIPhoneApplication.h"
#import "SUYUtils.h"
#import "SUYiCloudAccessor.h"

#import "SUYMIDISynth.h"

#import <SDCAlertView/SDCAlertView.h>

static uint sRestartCount = 0;

@implementation ScratchIPhoneAppDelegate

BOOL isRestarting = NO;
BOOL isUnfocued = NO;

@synthesize	 squeakProxy, presentationSpace, squeakVMIsReady, defaultSerialQueue;

- (void) makeMainWindowOnMainThread
{
	
	//This is fired via a cross thread message send from logic that checks to see if the window exists in the squeak thread.
	// Set up content view
    
	CGSize mainScreenSize = [SUYUtils scratchScreenSize];
	mainView = [[[self whatRenderCanWeUse] alloc] initWithFrame: CGRectMake(0,0,mainScreenSize.width,mainScreenSize.height)];
	self.mainView.clearsContextBeforeDrawing = NO;
	self.mainView.autoresizesSubviews= NO;
    
    //LgInfo(@"self.mainView.frame.size.width %f x height %f",self.mainView.frame.size.width, self.mainView.frame.size.height);
    [SUYUtils printMemStats];
    
	//Setup the scroll view which wraps the mainView
	presentationSpace = [[ScratchIPhonePresentationSpace alloc] initWithNibName:@"ScratchIPhonePresentationSpaceiPad" bundle:[NSBundle mainBundle]];
    
    self.scrollView = presentationSpace.scrollView;
	
}

- (BOOL)application: (UIApplication *)application didFinishLaunchingWithOptions: (NSDictionary*) launchOptions  {
    
    self.resourseLoadedCount = 0;
    if(defaultSerialQueue == nil){ defaultSerialQueue = dispatch_queue_create("ScratchIPhoneAppDelegate", DISPATCH_QUEUE_SERIAL);}
    
	[self listenNotifications];
	[super application: application didFinishLaunchingWithOptions: launchOptions];
    
	SUYLauncherViewController *launcherViewController;
	if(SUYUtils.isIPadIdiom) {
		Class loginViewControlleriPadClass = NSClassFromString(@"SUYLauncherViewController");
		launcherViewController = [[loginViewControlleriPadClass alloc] initWithNibName:@"LauncherViewController" bundle:[NSBundle mainBundle]];
	} else {
		LgWarn(@"iPad only!");
        return NO;
	}
    
#if TARGET_OS_MACCATALYST
    NSSet<UIScene*> *scenes = UIApplication.sharedApplication.connectedScenes;
    for (UIScene* scene in scenes) {
        UIWindowScene* winScene = ((UIWindowScene*)scene);
        winScene.titlebar.titleVisibility = UITitlebarTitleVisibilityHidden;
        winScene.titlebar.toolbar = nil;
        float height = winScene.screen.bounds.size.height;
        float width = (4 * height / 3) + 30;
        winScene.sizeRestrictions.minimumSize = CGSizeMake(width, height);
        //winScene.sizeRestrictions.maximumSize = CGSizeMake(width, height);
    }
#endif
    
	viewController = [[SUYNavigationController alloc] initWithRootViewController: launcherViewController];
	[launcherViewController release];
	
	self.viewController.navigationBarHidden = YES;
    self.viewController.toolbarHidden = YES;
    [self.window setRootViewController: viewController];
  
    _mailComposer = [[SUYMailComposer alloc] init];
    _mailComposer.viewController = self.viewController;
    
    _microbitAccessor = [[SUYMicrobitAccessor alloc] init];

#if TARGET_OS_MACCATALYST
    _sensorAccessor = [[SUYDummySensorAccessor alloc] init];
#else
    _sensorAccessor = [[SUYSensorAccessor alloc] init];
#endif
    
   	[window makeKeyAndVisible];
    isRestarting = NO;
    
    [[SUYiCloudAccessor soleInstance] detectiCloud];
    
    NSURL *url = (NSURL *)[launchOptions valueForKey:UIApplicationLaunchOptionsURLKey];
    
    if(url == nil || ![url isFileURL]){ return NO;}
       
    return YES;
    
}

- (BOOL)application:(nonnull UIApplication *)application openURL:(nonnull NSURL *)url options: (nonnull NSDictionary<NSString *,id> *)options {
    //TODO: Prohibit request from com.apple.mobilemail
    LgInfo(@"###openURL: %@", url);
    
    //iCloud-Inbox
    if([SUYUtils belongsToTempDirectory: url.path]){
        return [self openOrSaveFixingResourcePathOnTempDirectory: url];
    }
    
    //External File Provider
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager isReadableFileAtPath: url.path] == NO){
        return [self openOrSaveFixingResourcePathOnExernalDirectory: url];
    }
    
    //Mail, AirDrop
    LgInfo(@"###openURL: Mail, AirDrop handling");
    NSString *toPath = url.path;
    toPath = [toPath precomposedStringWithCanonicalMapping];
    if (self.resourcePathOnLaunch == nil || self.resourseLoadedCount > 0) {
        [self trimResourcePathOnLaunch: toPath];
        [self openOrSaveResourcePath:toPath saveTitle: @"New entry in Inbox"];
    } else {
        self.resourcePathOnLaunch = toPath;
    }
    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application{
    [self becomeBackground];
    LgInfo(@"!! applicationDidEnterBackground !!");
}

- (void) applicationDidBecomeActive:(UIApplication *)application{
    [self becomeActive];
    LgInfo(@"!! applicationDidBecomeActive !!");
}

#pragma mark Private
-(void) trimResourcePathOnLaunch: (NSString*) resourcePath
{
    if([resourcePath hasPrefix:[SUYUtils documentInboxDirectory]] == NO){return;}
    NSInteger maxNum = [(sqSqueakIPhoneInfoPlistInterface*) self.squeakApplication.infoPlistInterfaceLogic inboxMaxNumOfItems];
    [[SUYUtils class] trimResourcePathOnLaunch: resourcePath max: (int)maxNum];
}

- (BOOL) openOrSaveFixingResourcePathOnTempDirectory: (nonnull NSURL*) url {
    NSString *docInboxDir = [SUYUtils documentDirectory];
    NSString *toPath = [docInboxDir stringByAppendingPathComponent: url.lastPathComponent];
    toPath = [toPath precomposedStringWithCanonicalMapping];
    NSData *data = [NSData dataWithContentsOfURL:url];
    BOOL result = [data writeToFile:toPath atomically:YES];
    if(!result){ return NO;}
    LgInfo(@"###openURL: iCloud file copied to %@", toPath);
    if(self.resourcePathOnLaunch == nil || self.resourseLoadedCount > 0){
        [self openOrSaveResourcePath:toPath saveTitle: @"New entry in Documents"];
    } else {
        self.resourcePathOnLaunch = toPath;
    }
    return YES;
}
- (BOOL) openOrSaveFixingResourcePathOnExernalDirectory: (nonnull NSURL*) url {
    NSError *error = nil;
    NSString *docInboxDir = [SUYUtils documentDirectory];
    NSString *toPath = [docInboxDir stringByAppendingPathComponent: url.lastPathComponent];
    toPath = [toPath precomposedStringWithCanonicalMapping];
    BOOL allowed = [url startAccessingSecurityScopedResource];
    
    NSNumber *isIniCloud = nil;
    if ([url getResourceValue:&isIniCloud forKey:NSURLIsUbiquitousItemKey error:nil] && ([isIniCloud boolValue])) {
        NSFileManager *fm = [NSFileManager defaultManager];
        [fm startDownloadingUbiquitousItemAtURL: url error:&error];
        if(error){
            LgError(@"Error downloading iCloud resource: %@", error);
            if(allowed){[url stopAccessingSecurityScopedResource];}
            return NO;
        }
    }
    
    //Load data by FileCordinator
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [fileCoordinator coordinateReadingItemAtURL:url options:NSFileCoordinatorReadingWithoutChanges error:&error byAccessor:^(NSURL *newUrl) {
        NSError *errorInAccess = nil;
        NSData *data = nil;
        data = [NSData dataWithContentsOfURL:newUrl options:nil error:&errorInAccess];
        if(allowed){[url stopAccessingSecurityScopedResource];}
        if(errorInAccess){
            LgError(@"Error downloading iCloud resource: %@", errorInAccess);
        }
        BOOL result = [data writeToFile:toPath atomically:YES];
        if(result == NO){
            LgInfo(@"Error writing new file to: %@", toPath);
            return;
        }
        LgInfo(@"###openURL: external file copied to %@", toPath);
        if(self.resourcePathOnLaunch == nil || self.resourseLoadedCount > 0){
            [self openOrSaveResourcePath:toPath saveTitle: @"New entry in Documents"];
        } else {
            self.resourcePathOnLaunch = toPath;
        }
    }];
    
    return YES;
}


#pragma mark Accessing

- (sqSqueakMainApplication *)  newApplicationInstance {
	return [sqScratchIPhoneApplication new];
}


#pragma mark Notifications
- (void)listenNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveSqueakVMReady) name:@"squeakVMReady" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveSqueakVMSpaceIsLow) name:@"squeakVMSpaceIsLow" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(errorMailReported) name:@"errorMailReported" object:nil];
    
    if(SUYUtils.isOnMac){
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowFocused:) name:@"NSWindowDidBecomeMainNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowUnfocused:) name:@"NSWindowDidResignMainNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowResized:) name:@"NSWindowDidResizeNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deferRestoreWindow:) name:@"NSWindowDidChangeScreenNotification" object:nil];
    }
    
}

- (void)forgetNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

#pragma mark Callback
- (void) didReceiveSqueakVMReady {
	self.squeakVMIsReady = YES;
}

- (void) didReceiveSqueakVMSpaceIsLow {
	LgWarn(@"! didReceiveSqueakVMSpaceIsLow !");
    
    dispatch_async (
            dispatch_get_main_queue(),
            ^{
                [self enterRestart];
            }
    );
}

- (void) errorMailReported {
	LgWarn(@"! errorMailReported !");
    [self enterRestart];
}

#pragma mark Callback for Mac
- (void) windowFocused: (NSNotification *)notification {
    if(isUnfocued == NO) return;
    if([self deferRestoreWindow: notification]){
        isUnfocued = NO;
    }
}
- (void) windowUnfocused: (NSNotification *)notification {
    if(isUnfocued == YES) return;
    if([self deferRestoreWindow: notification]){
        isUnfocued = YES;
    }
}
- (BOOL) deferRestoreWindow: (NSNotification *)notification {
    if(![self isScratchMainWindow: notification.object]) return NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 100* NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
        [self restoreDisplay];
    });
    return YES;
}
- (void) windowResized: (NSNotification *)notification {
    if(![self isScratchMainWindow: notification.object]) return;
    [self.presentationSpace fixLayoutOnWindowResizing];
    [self restoreDisplay];
}

- (BOOL) isScratchMainWindow: (id) object {
    if([object respondsToSelector:@selector(frame)]){
        CGSize notifierSize = [object frame].size;
        CGSize scratchScreenSize = SUYUtils.scratchScreenSize;
        CGFloat defaultHeight = scratchScreenSize.height;
        CGFloat defaultWidth = scratchScreenSize.width;
        NSString* className = NSStringFromClass([object class]);
        //LgInfo(@"%@ > %f %f : %f %f", className, defaultHeight, defaultWidth, notifierSize.height, notifierSize.width);
        if(defaultHeight > notifierSize.height && defaultWidth > notifierSize.width
           && ([className hasPrefix: @"UINS"] == NO))
        {
            return NO;
        }
    }
    return YES;
}

#pragma mark -
#pragma mark Accessing
- (UIScrollView *)scratchPlayView
{
    return self.presentationSpace.scrollView;
}


- (BOOL) sizeOfMemoryIsTooLowForLargeImages {
    //iPad has plenty of memories
	return NO;
}

- (uint) squeakMemoryBytesLeft {
    extern uint sqAvailableHeapSize();
    return sqAvailableHeapSize();
}


-(uint) squeakMaxHeapSize {
    extern usqInt gMaxHeapSize;
    return gMaxHeapSize;
}

-(uint) restartCount {
    return sRestartCount;
}

#pragma mark - Opening

- (void) openDefaultProject{
    if(self.resourcePathOnLaunch == nil){
        [self openResource:@""];
    } else {
        NSString *resourcePath = self.resourcePathOnLaunch;
        [self trimResourcePathOnLaunch: resourcePath];
        [self openResource: resourcePath];
    }
}

- (void) openImporting: (NSURL*) externalFileUrl {
    [[SUYiCloudAccessor soleInstance] openUrl:externalFileUrl succeeded:^(NSString *pathStr) {
        [self openResource:[pathStr copy]];
    }];
}

- (void) openOrSaveResourcePath: (NSString*) resourcePath saveTitle: (NSString*) title {
    
    if(self.resourseLoadedCount == 0){
        self.resourcePathOnLaunch = resourcePath;
        return;
    }
    
    if([presentationSpace isViewModeBarHidden]){
        [SUYUtils alertInfo: [NSString stringWithFormat: @"%@: %@", NSLocalizedString(title,nil), [resourcePath.lastPathComponent stringByDeletingPathExtension]]];
    } else {
        [self openResource:resourcePath];
    }
}

#pragma mark -
#pragma mark ScratchAdapter

- (void) openResource:(NSString*)resourcePathName{
    LgInfo(@"###resourcePath %@", resourcePathName);
    [squeakProxy chooseThisProject: resourcePathName runProject: NO];
    self.resourseLoadedCount++;
}

- (void) shoutGo{
    [squeakProxy shoutGo];
}

- (void) stopAll{
    [squeakProxy stopAll];
}

- (void) exitPresentationMode{
    [squeakProxy exitPresentationMode];
}

- (void) commandKeyStateChanged:(BOOL)state{
    int stateNum = state==YES? 1 : 0;
    [squeakProxy commandKeyStateChanged: stateNum];
}

- (void) shiftKeyStateChanged:(BOOL)state{
    [squeakProxy shiftKeyStateChanged: state];
}

- (void) setViewModeIndex:(int)mode{
    [squeakProxy setViewModeIndex: mode];
}

- (int)  getViewModeIndex{
    return [squeakProxy getViewModeIndex];
}

- (void)  becomeActive{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if(squeakVMIsReady){[squeakProxy becomeActive];}
        dispatch_async(dispatch_get_main_queue(), ^{
            [[SUYMIDISynth soleInstance] reset];
        });
    });
}

- (void)  becomeBackground{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if(squeakVMIsReady){
            [squeakProxy restoreDisplay];
            [squeakProxy becomeBackground];
        }
    });
}

- (void) restoreDisplay{
    if(squeakProxy){
        [squeakProxy restoreDisplay];
    }
}

- (void) restartVm {
    @synchronized(self){
    if(isRestarting==YES){return;}
    isRestarting = YES;
    [squeakProxy restartVm];
    }
}

- (void) setFontScaleIndex: (int)idx{
    if([self.presentationSpace viewModeIndex] == 2){
        return;
    }
    if(squeakProxy){
        [squeakProxy setFontScaleIndex: idx];
    }
}

- (int)  getFontScaleIndex{
    return [squeakProxy getFontScaleIndex];
}

- (BOOL) scriptsAreRunning{
    int runFlag = [squeakProxy scriptsAreRunning];
    return runFlag > 0;
}

- (void) pickPhoto: (NSString *)filePath {
    if(squeakProxy){
        [squeakProxy pickPhoto: filePath];
    }
}

- (void) flushInputString: (NSString *)inputString {
    if(squeakProxy){
        [squeakProxy flushInputString: inputString];
    }
}

- (BOOL) meshIsRunning {
    int runFlag = [squeakProxy meshIsRunning];
    return runFlag > 0;
}
- (void) meshJoin: (NSString *)inputString {
    if(squeakProxy){
        NSString* str = [inputString copy];
        [squeakProxy meshJoin: str];
    }
}
- (BOOL) meshJoined: (NSString *)inputString {
    int result = [squeakProxy meshJoined: inputString];
    return result > 0;
}
- (void) meshRun: (int) runOrNot {
    if(squeakProxy){
        [squeakProxy meshRun: runOrNot];
    }
}

#pragma mark-
#pragma mark ScratchAdapter - Testing
- (int) catalystMode {
    return SUYUtils.isOnMac ? 1 : 0;
}
- (float) osVersion {
    return SUYUtils.osVersion;
}
#pragma mark -
#pragma mark Rotation
- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window{
    return UIInterfaceOrientationMaskAll;
}


#pragma mark -
#pragma mark Actions

- (void)openCamera:(NSString *)clientMode {
    [self.presentationSpace performSelectorOnMainThread:@selector(openCamera:) withObject: clientMode waitUntilDone: NO];
}

- (void)openPhotoLibraryPicker:(NSString *)clientMode {
    [self.presentationSpace performSelectorOnMainThread:@selector(openPhotoLibraryPicker:) withObject: clientMode waitUntilDone: NO];
}

- (void)openHelp:(NSString *)url {
    [self.presentationSpace performSelectorOnMainThread:@selector(openHelp:) withObject: url waitUntilDone: NO];
}

- (void)showWaitIndicator{
    [self.presentationSpace performSelectorOnMainThread:@selector(showWaitIndicator) withObject: nil waitUntilDone: NO];
}

- (void)hideWaitIndicator{
    [self.presentationSpace performSelectorOnMainThread:@selector(hideWaitIndicator) withObject: nil waitUntilDone: NO];
}

- (void) textMorphFocused: (NSString *)status {
    [self performSelectorOnMainThread:@selector(basicTextMorphFocused:) withObject: status waitUntilDone: NO];
}

- (void) basicTextMorphFocused: (NSString *)status {
    BOOL stat = [status isEqualToString:@"true"];
    [self.presentationSpace textMorphFocused: stat];
}

#pragma mark -
#pragma mark Bailing

- (void) bailWeAreBrokenOnMainThread: (NSString *) oopsText {
    
	_mailComposer.brokenWalkBackString = oopsText;
    
    NSLog(@"!!St Walkback!!: %@", oopsText);
    
	[self terminateActivityView];
    
    NSString *cough = NSLocalizedString(@"Cough",nil);
    NSString *massive = NSLocalizedString(@"Massive",nil);
    NSString *reset = NSLocalizedString(@"Reset",nil);
    NSString *email = NSLocalizedString(@"Email",nil);
    
    SDCAlertController *alert = [SUYUtils newAlert: massive title: cough];
    
    [alert addAction:[[SDCAlertAction alloc] initWithTitle:reset style:UIAlertActionStyleDefault handler:^(SDCAlertAction *action) {
        if(isRestarting==NO){
            isRestarting = YES;
            [self enterRestart];
        }
    }]];
    
    if ([SUYUtils canSendMail]){
        [alert addAction:[[SDCAlertAction alloc] initWithTitle:email style:UIAlertActionStyleDefault handler:^(SDCAlertAction *action) {[_mailComposer reportErrorByEmail];}]];
    }
    
    [self.viewController presentViewController:alert animated:YES completion:nil];

}	

- (void) bailWeAreBroken: (NSString *) oopsText {
	[self performSelectorOnMainThread:@selector(bailWeAreBrokenOnMainThread:) withObject: oopsText waitUntilDone: NO];
}

#pragma mark -
#pragma mark Mail

- (void)mailProject: (NSString *)projectPath {
    [_mailComposer performSelectorOnMainThread:@selector(mailProject:) withObject: projectPath waitUntilDone: NO];
}

#pragma mark AirDrop
- (void)airDropProject: (NSString *)projectPath {
    dispatch_async (
        dispatch_get_main_queue(), ^{
            [presentationSpace airDropProject: projectPath];
        }
    );
}

#pragma mark iCloud
- (void)exportToCloud: (NSString *)resourcePath {
    dispatch_async (
        dispatch_get_main_queue(), ^{
            [presentationSpace exportToCloud: resourcePath];
        }
    );
}
- (void)importFromCloud {
    dispatch_async (
        dispatch_get_main_queue(), ^{
            [presentationSpace importFromCloud];
        }
    );
}

#pragma mark Mesh
- (void) openMeshDialog {
    dispatch_async (
        dispatch_get_main_queue(), ^{
            [presentationSpace openMeshDialog];
        }
    );
}

#pragma mark Cursor
- (void) showCursor:(int)cursorCode {
    //Hack for TouchVisualizer bug
    if([SUYUtils cursorEnabled]){return;}
    dispatch_async (
        dispatch_get_main_queue(), ^{
            [presentationSpace.softKeyboardField becomeFirstResponder];
            [presentationSpace.softKeyboardField resignFirstResponder];
            [SUYUtils showCursor:cursorCode];
        }
    );
    
}
- (void) hideCursor {
    dispatch_async (
        dispatch_get_main_queue(), ^{
            [SUYUtils hideCursor];
        }
    );
}

#pragma mark -
#pragma mark Mac Catalyst

- (void)buildMenuWithBuilder:(id<UIMenuBuilder>)builder{
    [super buildMenuWithBuilder: builder];
    if(builder.system != [UIMenuSystem mainSystem]) return;
    
    NSString* versionStr = [self.squeakApplication.infoPlistInterfaceLogic fullVersionString];
    UICommand* command = [UICommand commandWithTitle:versionStr image:nil action:@selector(restoreDisplay) propertyList:nil];
    UIMenu* aboutMenu = [UIMenu menuWithTitle:(NSLocalizedString(@"Version",nil)) children: @[command]];
    
    [builder replaceMenuForIdentifier:(UIMenuAbout) withMenu:aboutMenu];
    [builder removeMenuForIdentifier:(UIMenuServices)];
    [builder removeMenuForIdentifier:(UIMenuFile)];
    [builder removeMenuForIdentifier:(UIMenuEdit)];
    [builder removeMenuForIdentifier:(UIMenuFormat)];
}

- (void) restoreDisplayIfNeeded {
    if(SUYUtils.isOnMac){
        dispatch_async(dispatch_get_main_queue(), ^{
            [self restoreDisplay];
        });
    }
}

#pragma mark -
#pragma mark Restart

- (void) enterRestart {
    dispatch_async (
           dispatch_get_main_queue(),
           ^{
            LgInfo(@"!! RequestRestart !!");
            [[NSNotificationCenter defaultCenter] postNotificationName: @"squeakVmWillReset" object:self];
            [_mailComposer abort];
            [SUYUtils inform:(NSLocalizedString(@"Cleaning up memory...",nil)) duration:800];
            [self restartAfterDelay];
           }
    );
}


- (void) restartAfterDelay {
    [squeakProxy release];
	[self.squeakThread cancel];
	[self performSelector: @selector(restartGradually) withObject: nil afterDelay: 1.5];
}

- (void) restartGradually {
	while (![self.squeakThread isFinished]) {}
	extern int sqMacMemoryFree();
	sqMacMemoryFree();
	self.squeakThread = nil;
    
    [UIView animateWithDuration:0.8
                     animations:^{self.presentationSpace.view.alpha = 0.8;}
                     completion:^(BOOL finished){ [self.presentationSpace.view removeFromSuperview];}];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.8 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
	[viewController popToRootViewControllerAnimated: YES];
    
	self.mainView = nil;
	self.scrollView = nil;
        
    self.mailComposer = nil;
    self.sensorAccessor = nil;
    self.microbitAccessor = nil;
    
	self.presentationSpace  = nil;
	if (self.screenAndWindow.blip) {
		[self.screenAndWindow.blip invalidate];
		self.screenAndWindow.blip = nil;
	}
	self.screenAndWindow  = nil;
	self.squeakVMIsReady = NO;
    self.defaultSerialQueue = nil;
    
    [self forgetNotifications];
        
    [UIView animateWithDuration:0.2
                         animations:^{viewController.view.alpha = 0.0;}
                         completion:^(BOOL finished){ [viewController.view removeFromSuperview];}];
    
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        self.viewController = nil;
        self.squeakProxy  = nil;
        self.squeakApplication = nil;
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self application: [UIApplication sharedApplication] didFinishLaunchingWithOptions: nil];
    });
    sRestartCount++;
}

#pragma mark -
#pragma mark Release
- (void)dealloc {
	[super dealloc];
    [self forgetNotifications];
	[squeakProxy release];
	[presentationSpace release];
    [defaultSerialQueue release];
    [_mailComposer release];
    [_sensorAccessor release];
    [_microbitAccessor release];
}

@end




