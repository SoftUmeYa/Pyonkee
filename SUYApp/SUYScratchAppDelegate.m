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


static uint sRestartCount = 0;

@implementation ScratchIPhoneAppDelegate

BOOL isRestarting = NO;

@synthesize	 squeakProxy, presentationSpace, squeakVMIsReady, defaultSerialQueue, mailComposer;

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
    
    if(defaultSerialQueue == nil){ defaultSerialQueue = dispatch_queue_create("ScratchIPhoneAppDelegate", DISPATCH_QUEUE_SERIAL);}
    
	[self listenNotifications];
	[super application: application didFinishLaunchingWithOptions: launchOptions];
    
	SUYLauncherViewController *launcherViewController;
	if( UIUserInterfaceIdiomPad == UI_USER_INTERFACE_IDIOM() ) {
		Class loginViewControlleriPadClass = NSClassFromString(@"SUYLauncherViewController");
		launcherViewController = [[loginViewControlleriPadClass alloc] initWithNibName:@"LauncherViewController" bundle:[NSBundle mainBundle]];
	} else {
		LgWarn(@"iPad only!");
        return NO;
	}
	viewController = [[SUYNavigationController alloc] initWithRootViewController: launcherViewController];
	[launcherViewController release];
	
	self.viewController.navigationBarHidden = YES;
    self.viewController.toolbarHidden = YES;
    [self.window setRootViewController: viewController];
  
    mailComposer = [[SUYMailComposer alloc] init];
    mailComposer.viewController = self.viewController;
    
   	[window makeKeyAndVisible];
    isRestarting = NO;
    
    NSURL *url = (NSURL *)[launchOptions valueForKey:UIApplicationLaunchOptionsURLKey];
    
    if (url != nil && [url isFileURL]) {
        self.clickedResourcePathOnLaunch = url.path;
    } else {
        self.clickedResourcePathOnLaunch = nil;
    }
    
    return YES;
    
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    //TODO: Prohibit request from com.apple.mobilemail
    if (self.clickedResourcePathOnLaunch == nil && url != nil && [url isFileURL]) {
        
        [self trimResourcePathOnLaunch: url.path]; //MARK: Auto removing the oldest project => better to be off?
        
        if([presentationSpace isViewModeBarHidden]){
            [[[UIAlertView alloc] initWithTitle:@""
                    message: [NSString stringWithFormat: @"%@: %@", NSLocalizedString(@"New entry in Inbox",nil), [url.lastPathComponent stringByDeletingPathExtension]]
                    delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil] show];
        } else {
            [self openProject:url.path];
        }
        
    }
    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application{
    [self getViewModeIndex];
    LgInfo(@"!! applicationDidEnterBackground !!");
}

- (void) applicationDidBecomeActive:(UIApplication *)application{
    [self becomeActive];
    LgInfo(@"!! applicationDidBecomeActive !!");
}

#pragma mark Private
-(void) trimResourcePathOnLaunch: (NSString*) resourcePath
{
    NSInteger maxNum = [(sqSqueakIPhoneInfoPlistInterface*) self.squeakApplication.infoPlistInterfaceLogic inboxMaxNumOfItems];
    [[SUYUtils class] trimResourcePathOnLaunch: resourcePath max: (int)maxNum];
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
}

- (void)forgetNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

#pragma mark Callbnack
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

#pragma mark -
#pragma mark Alert Delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    // error in squeak
	if (buttonIndex==1) {
		[mailComposer reportErrorByEmail];
        return;
    }
    if(isRestarting==NO){
        isRestarting = YES;
        [self enterRestart];
    }
}


#pragma mark -
#pragma mark ScratchAdapter

- (void) openDefaultProject{
    if(self.clickedResourcePathOnLaunch == nil){
        [self openProject:@""];
    } else {
        [self trimResourcePathOnLaunch: self.clickedResourcePathOnLaunch];
        [self openProject: self.clickedResourcePathOnLaunch];
        self.clickedResourcePathOnLaunch = nil;
    }
}

- (void) openProject:(NSString*)projectPathName{
    [squeakProxy chooseThisProject: projectPathName runProject: NO];
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
    if(squeakVMIsReady){
        [squeakProxy becomeActive];
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

#pragma mark -
#pragma mark Rotation
- (NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window{
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
    
	mailComposer.brokenWalkBackString = oopsText;
    
    NSLog(@"!!St Walkback!!: %@", oopsText);
    
	[self terminateActivityView];
	UIAlertView *alertView = [UIAlertView alloc];
	NSString *cough = NSLocalizedString(@"Cough",nil);
	NSString *massive = NSLocalizedString(@"Massive",nil);
	NSString *reset = NSLocalizedString(@"Reset",nil);
	NSString *email = NSLocalizedString(@"Email",nil);
    if ([SUYUtils canSendMail]){
		alertView = [alertView initWithTitle: cough message: massive delegate: self cancelButtonTitle: reset otherButtonTitles: email,nil];
    } else {
        alertView = [alertView initWithTitle: cough message: massive delegate: self cancelButtonTitle: reset otherButtonTitles: nil];
    }
	[alertView show];
	[alertView release];
}	

- (void) bailWeAreBroken: (NSString *) oopsText {
	[self performSelectorOnMainThread:@selector(bailWeAreBrokenOnMainThread:) withObject: oopsText waitUntilDone: NO];
}

#pragma mark -
#pragma mark Mail

- (void)mailProject: (NSString *)projectPath {
    [mailComposer performSelectorOnMainThread:@selector(mailProject:) withObject: projectPath waitUntilDone: NO];
}

#pragma mark AirDrop
- (void)airDropProject: (NSString *)projectPath {
    [presentationSpace airDropProject: projectPath];
}


#pragma mark -
#pragma mark Restart

- (void) enterRestart {
    dispatch_async (
           dispatch_get_main_queue(),
           ^{
            LgInfo(@"!! RequestRestart !!");
            [[NSNotificationCenter defaultCenter] postNotificationName: @"squeakVmWillReset" object:self];
            [mailComposer abort];
            [SUYUtils inform:(NSLocalizedString(@"Cleaning up memory...",nil)) duration:800 for:self];
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
    [mailComposer release];
}

@end




