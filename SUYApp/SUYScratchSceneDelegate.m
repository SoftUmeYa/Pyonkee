//
//  SUYScratchSceneDelegate.m
//  ScratchOnIPad
//
//  Created for SceneDelegate migration
//

#import "SUYScratchSceneDelegate.h"
#import "SUYScratchAppDelegate.h"
#import "SUYNavigationController.h"
#import "SUYLauncherViewController.h"
#import "SUYUtils.h"

@implementation SUYScratchSceneDelegate {
    BOOL _isUnfocused;  // Track window focus state for Mac Catalyst
    BOOL _isSqueakStarted;
}

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {

    // Ensure this is a window scene
    if (![scene isKindOfClass:[UIWindowScene class]]) {
        return;
    }

    self.appDelegate.currentSceneDelegate = self;

    // Create window for this scene
    _screenAndWindow =  [sqiPhoneScreenAndWindow new];
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
    
    // View controller setup
    SUYLauncherViewController *launcherViewController;
    if(SUYUtils.isIPadIdiom) {
        Class loginViewControlleriPadClass = NSClassFromString(@"SUYLauncherViewController");
        launcherViewController = [[loginViewControlleriPadClass alloc] initWithNibName:@"LauncherViewController" bundle:[NSBundle mainBundle]];
    } else {
        LgWarn(@"iPad only!");
        return;
    }
    
#if TARGET_OS_MACCATALYST
    // Mac Catalyst window configuration
    windowScene.titlebar.titleVisibility = UITitlebarTitleVisibilityHidden;
    windowScene.titlebar.toolbar = nil;
    float height = windowScene.screen.bounds.size.height;
    float width = (4 * height / 3) + 30;
    windowScene.sizeRestrictions.minimumSize = CGSizeMake(width, height);
    //windowScene.sizeRestrictions.maximumSize = CGSizeMake(width, height);
#endif

    self.viewController = [[SUYNavigationController alloc] initWithRootViewController:launcherViewController];
    
    self.viewController.navigationBarHidden = YES;
    self.viewController.toolbarHidden = YES;
    [self.window setRootViewController:self.viewController];

    // Update mail composer reference
    self.appDelegate.mailComposer.viewController = self.viewController;

    [self.window makeKeyAndVisible];

    // Setup Mac Catalyst window notifications
    [self setupMacCatalystNotifications];

    // Handle URL if app was launched with one
    NSSet<UIOpenURLContext *> *urlContexts = connectionOptions.URLContexts;
    if (urlContexts.count > 0) {
        UIOpenURLContext *context = urlContexts.anyObject;
        [self scene:scene openURLContexts:[NSSet setWithObject:context]];
    }
}

- (void)sceneDidDisconnect:(UIScene *)scene {
    // Called as the scene is being released by the system
    [self removeMacCatalystNotifications];
    [self.appDelegate invalidateSceneDelegateCache];
}

- (void)sceneDidBecomeActive:(UIScene *)scene {
    [self startSqueakThreadIfNeeded];
    [self.appDelegate becomeActive];
    LgInfo(@"!! sceneDidBecomeActive !!");
}

- (void)sceneWillResignActive:(UIScene *)scene {
    // Called when the scene will move from active to inactive state
}

- (void)sceneWillEnterForeground:(UIScene *)scene {
    // Called as the scene transitions from background to foreground
}

- (void)sceneDidEnterBackground:(UIScene *)scene {
    // Forward to AppDelegate business logic
    [self.appDelegate becomeBackground];
    LgInfo(@"!! sceneDidEnterBackground !!");
}

- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts {
    // Forward URL handling to AppDelegate
    for (UIOpenURLContext *context in URLContexts) {
        SUYScratchAppDelegate *appDelegate = (SUYScratchAppDelegate *)[UIApplication sharedApplication].delegate;
        [appDelegate application:[UIApplication sharedApplication]
                         openURL:context.URL
                         options:@{}];
    }
}

#pragma mark -
#pragma mark Actions
- (void) setupSqueakMainView
{
    
    //This is fired via a cross thread message send from logic that checks to see if the window exists in the squeak thread.
    // Set up content view
    
    CGSize mainScreenSize = [SUYUtils scratchScreenSize];
    _mainView = [[[self whatRenderCanWeUse] alloc] initWithFrame: CGRectMake(0,0,mainScreenSize.width,mainScreenSize.height)];
    _mainView.clearsContextBeforeDrawing = NO;
    _mainView.autoresizesSubviews= NO;
    
    //LgInfo(@"self.mainView.frame.size.width %f x height %f",self.mainView.frame.size.width, self.mainView.frame.size.height);
    [SUYUtils printMemStats];
    
    //Setup the scroll view which wraps the mainView
    _presentationSpace = [[ScratchIPhonePresentationSpace alloc] initWithNibName:@"ScratchIPhonePresentationSpaceiPad" bundle:[NSBundle mainBundle]];
    
    self.scrollView = _presentationSpace.scrollView;

}


- (void) startPlaying {
    LgInfo(@"startPlaying");
    [self.viewController pushViewController: _presentationSpace animated: YES];
}


#pragma mark -
#pragma mark Accessing
- (SUYScratchAppDelegate*)appDelegate {
    return (SUYScratchAppDelegate *)[UIApplication sharedApplication].delegate;
}

- (SqueakProxy*)squeakProxy {
    return [self appDelegate].squeakProxy;
}

#pragma mark -
#pragma mark Private

- (Class) whatRenderCanWeUse {
    return  [SUYUtils squeakUIViewClass];
}

- (void) startSqueakThreadIfNeeded {
    if(!_isSqueakStarted){
        if(!SUYUtils.isOnMac) [self.appDelegate startSqueakThread];
        _isSqueakStarted = YES;
    }
}

#pragma mark -
#pragma mark Restart

- (void) restart {
    [_viewController popToRootViewControllerAnimated: YES];

    if (self.screenAndWindow.blip) {
        [self.screenAndWindow.blip invalidate];
        self.screenAndWindow.blip = nil;
    }
    _screenAndWindow =  [sqiPhoneScreenAndWindow new];
}

#pragma mark -
#pragma mark Mac Catalyst Window Notifications

- (void) setupMacCatalystNotifications {
#if TARGET_OS_MACCATALYST
    if (SUYUtils.isOnMac) {
        _isUnfocused = NO;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(windowFocused:)
                                                     name:@"NSWindowDidBecomeMainNotification"
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(windowUnfocused:)
                                                     name:@"NSWindowDidResignMainNotification"
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(windowResized:)
                                                     name:@"NSWindowDidResizeNotification"
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(deferRestoreWindow:)
                                                     name:@"NSWindowDidChangeScreenNotification"
                                                   object:nil];
    }
#endif
}

- (void) removeMacCatalystNotifications {
#if TARGET_OS_MACCATALYST
    if (SUYUtils.isOnMac) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:@"NSWindowDidBecomeMainNotification"
                                                      object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:@"NSWindowDidResignMainNotification"
                                                      object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:@"NSWindowDidResizeNotification"
                                                      object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:@"NSWindowDidChangeScreenNotification"
                                                      object:nil];
    }
#endif
}

#pragma mark Mac Catalyst Window Notification Handlers

- (void) windowFocused:(NSNotification *)notification {
    if (_isUnfocused == NO) return;
    if ([self deferRestoreWindow:notification]) {
        _isUnfocused = NO;
    }
}

- (void) windowUnfocused:(NSNotification *)notification {
    if (_isUnfocused == YES) return;
    if ([self deferRestoreWindow:notification]) {
        _isUnfocused = YES;
    }
}

- (BOOL) deferRestoreWindow:(NSNotification *)notification {
    if (!self.appDelegate.squeakVMIsReady) return NO;
    if (![self isScratchMainWindow:notification.object]) return NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 100 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
        [self.appDelegate restoreDisplay];
    });
    return YES;
}

- (void) windowResized:(NSNotification *)notification {
    if (!self.appDelegate.squeakVMIsReady) return;
    if (![self isScratchMainWindow:notification.object]) return;
    [self.presentationSpace fixLayoutOnWindowResizing];
    [[self appDelegate] restoreDisplay];
}

- (BOOL) isScratchMainWindow:(id)object {
    if ([object respondsToSelector:@selector(frame)]) {
        CGSize notifierSize = [object frame].size;
        CGSize scratchScreenSize = SUYUtils.scratchScreenSize;
        CGFloat defaultHeight = scratchScreenSize.height;
        CGFloat defaultWidth = scratchScreenSize.width;
        NSString *className = NSStringFromClass([object class]);

        if (defaultHeight > notifierSize.height &&
            defaultWidth > notifierSize.width &&
            ([className hasPrefix:@"UINS"] == NO)) {
            return NO;
        }
    }
    return YES;
}

@end
