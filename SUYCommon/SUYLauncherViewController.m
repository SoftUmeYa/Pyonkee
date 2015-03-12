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

extern ScratchIPhoneAppDelegate *gDelegateApp;

@implementation SUYLauncherViewController

bool isEnabled = NO;

@synthesize loadingImage, cleaningImage, startButton, statusLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        squeakVMIsReady = NO;
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
	NSString *waitString = NSLocalizedString(@"Loading...",nil);
	[self.startButton setTitle: waitString forState:UIControlStateNormal];
    self.statusLabel.text = waitString;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear: animated];
	squeakVMIsReady = gDelegateApp.squeakVMIsReady;
	if (squeakVMIsReady){
		[self didReceiveSqueakVMReadyOnMainThread];
	}
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveSqueakVMReady) name:@"squeakVMReady" object:nil];
	self.startButton.enabled = uiThinksLoginButtonCouldBeEnabled = NO;
    [self selectLaunchImage];
}

- (void) viewDidAppear:(BOOL)animated {
	[super viewDidAppear: animated];
    uiThinksLoginButtonCouldBeEnabled = YES;
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

- (NSUInteger)supportedInterfaceOrientations{
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
    [gDelegateApp turnActivityViewOn];
    [gDelegateApp.viewController pushViewController: gDelegateApp.presentationSpace animated: YES];
}

- (void) showCleaningImage {
    self.cleaningImage.hidden = NO;
    self.loadingImage.hidden = YES;
}

#pragma mark -
#pragma mark Callback

- (void) didReceiveSqueakVMReadyOnMainThread {
    self.startButton.enabled = squeakVMIsReady = YES;
	NSString *playStr = NSLocalizedString(@"Play!",nil);
	[self.startButton setTitle: playStr forState:UIControlStateNormal];
    self.statusLabel.text = playStr;
	isEnabled = uiThinksLoginButtonCouldBeEnabled && squeakVMIsReady;
    
    if(isEnabled){
        dispatch_async (
             dispatch_get_main_queue(),
             ^{
                 [self startPlaying];
             }
        );
    } else {
        self.startButton.hidden = NO;
        self.statusLabel.hidden = YES;
    }
    
    
}

- (void) didReceiveSqueakVMReady {
	[self performSelectorOnMainThread:@selector(didReceiveSqueakVMReadyOnMainThread) withObject: nil waitUntilDone: NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    self.loadingImage = nil;
    self.cleaningImage = nil;
    
}

#pragma mark -
#pragma mark Private
- (void) selectLaunchImage {
    if([gDelegateApp restartCount] > 0){
        LgInfo(@"cleaning %u", [gDelegateApp restartCount]);
        [self showCleaningImage];
    }
}

@end
