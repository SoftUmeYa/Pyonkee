//
//  LauncherViewController.h
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2014/04/10.
//
//

#import "SUYLauncherViewController.h"
#import "SUYScratchAppDelegate.h"
#import "SUYInitializer.h"
#import "SUYScratchSceneDelegate.h"

@implementation SUYLauncherViewController

bool isEnabled = NO;

@synthesize loadingImage, cleaningImage, startButton, statusLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        uiThinksLoginButtonCouldBeEnabled = NO;
    }
	return self;
}

- (void)loadView {
	[super loadView];
	self.title = NSLocalizedString(@"Launch",nil);
    [SUYInitializer init];
    
}

- (void) viewDidLoad {
	[super viewDidLoad];
    uiThinksLoginButtonCouldBeEnabled = YES;
	NSString *waitString = NSLocalizedString(@"Loading...",nil);
	[self.startButton setTitle: waitString forState:UIControlStateNormal];
    self.statusLabel.text = waitString;
    self.startButton.hidden = YES;
    self.statusLabel.hidden = NO;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear: animated];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveSqueakVMReady) name:@"squeakVMReady" object:nil];
	self.startButton.enabled = uiThinksLoginButtonCouldBeEnabled;
    [self selectLaunchImage];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear: animated];
    [self startAutoOrManually];
}

- (void)viewWillDisappear:(BOOL)animated {
	[[NSNotificationCenter defaultCenter] removeObserver: self];
}


- (BOOL)isDataSourceAvailable {
	return YES;
}

#pragma mark Rotation
- (UIInterfaceOrientation) preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationLandscapeLeft;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskLandscape;
}

- (BOOL)shouldAutorotate{
    return YES;
}


#pragma mark -
#pragma mark Actions
- (IBAction) clickStartButton:(id)sender {
	[self startPlaying];
}

- (void)startPlaying {
    [self.appDelegate.currentSceneDelegate startPlaying];
}

- (void) showCleaningImage {
    self.cleaningImage.hidden = NO;
    self.loadingImage.hidden = YES;
}

#pragma mark -
#pragma mark Callback

- (void) didReceiveSqueakVMReadyOnMainThread {
    self.statusLabel.text = NSLocalizedString(@"Play!",nil);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self startPlaying];
    });
}

- (void) didReceiveSqueakVMReady {
	[self performSelectorOnMainThread:@selector(didReceiveSqueakVMReadyOnMainThread) withObject: nil waitUntilDone: NO];
}

#pragma mark -
#pragma mark Private
- (void) selectLaunchImage {
    if([self.appDelegate restartCount] > 0){
        LgInfo(@"cleaning %u", [self.appDelegate restartCount]);
        [self showCleaningImage];
    }
}

- (void)startAutoOrManually {
    if (self.appDelegate.squeakVMIsReady){
        [self startPlaying];
    } else {
//        Currently off
//        [self activateStartButtonIfNeeded];
    }
}

- (void) activateStartButtonIfNeeded {
    [self.startButton setTitle: NSLocalizedString(@"Play!",nil) forState:UIControlStateNormal];
    self.startButton.hidden = NO;
    self.statusLabel.hidden = YES;
}

#pragma mark -
#pragma mark Accessing

- (SUYScratchAppDelegate *)appDelegate
{
    SUYScratchAppDelegate *appDele = (SUYScratchAppDelegate*)[[UIApplication sharedApplication] delegate];
    return appDele;
}

@end
