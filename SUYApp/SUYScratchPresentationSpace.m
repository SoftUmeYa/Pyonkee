//
//  SUYScratchPresentationSpace.m
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2014/06/20
//  Modified, customized version of ScratchIPhonePresentationSpace.m
//
//  Originally Created by John M McIntosh on 10-02-15.
//  Copyright 2010 Corporate Smalltalk Consulting Ltd. All rights reserved.
//
//  

#import "SUYScratchPresentationSpace.h"
#import "SUYScratchAppDelegate.h"
#import "SqueakUIController.h"
#import "sqSqueakIPhoneInfoPlistInterface.h"

#import "SUYUtils.h"
#import "SUYFontResizeViewController.h"
#import "SUYCameraViewController.h"
#import "SUYPhotoPickViewController.h"
#import "SUYWebViewController.h"

#import "Pyonkee-Swift.h"

#import <QuartzCore/QuartzCore.h>

extern ScratchIPhoneAppDelegate *gDelegateApp;
static const int kCommandAutoUpSeconds = 2;
static const int kShiftAutoUpSeconds = 20;

@implementation ScratchIPhonePresentationSpace{
    CGFloat _originalScrollerScale;
    UIColor* _originalBackgroundColor;
    NSInteger _originalEditModeIndex;
    BOOL _useIme;
    UIInterfaceOrientation _formerOrientation;
    NSString* _lastExportResourcePath;
    NSInteger _exportResourceRetryCount;
}

@synthesize scrollView,scrollViewController,fontScaleButton, radioButtonSetController,
	textField,repeatKeyDict,
    softKeyboardField, softKeyboardOnButton,
	shoutGoLandscapeButton,stopAllLandscapeButton,landscapeToolBar,landscapeToolBar2,padLockButton,
    commandButton, shiftButton,
	indicatorView, viewModeBar, presentationExitButton;


uint warningMinHeapThreshold;
uint memoryWarningCount;

#pragma mark Initialization
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		repeatKeyDict = [[NSMutableDictionary alloc] init];
	}
    return self;
}


#pragma mark View Callback
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    _useIme = NO;

	self.textField.keyboardAppearance = UIKeyboardAppearanceAlert;
    self.softKeyboardField.hidden = YES;
	 
	[self.scrollView addSubview: gDelegateApp.mainView];
    self.scrollView.contentSize = gDelegateApp.mainView.bounds.size;
    
    self.viewModeBar.layer.cornerRadius = 5;
    self.viewModeBar.layer.masksToBounds = YES;
    
    _originalScrollerScale = [SUYUtils scratchScreenZoomScale];
    [self.scrollView setZoomScale: _originalScrollerScale animated: NO];
    self.scrollView.minimumZoomScale = [SUYUtils scratchScreenZoomScale];
    self.scrollView.maximumZoomScale = 8;
    [self.scrollView flashScrollIndicators];
    
    _originalBackgroundColor = self.view.backgroundColor;
    _originalEditModeIndex = 1;
    
    warningMinHeapThreshold = [gDelegateApp squeakMaxHeapSize] * 0.70;
    memoryWarningCount = 0;
    
    _formerOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
}

- (void) viewWillAppear:(BOOL)animated {
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible: NO];
	[gDelegateApp.viewController setNavigationBarHidden: YES animated: YES];
	
	self.scrollView.delaysContentTouches = self.padLockButton.selected;
    self.radioButtonSetController.selectedIndex = _originalEditModeIndex;
    [self keyboardDidChange:nil];
    [self listenNotifications];
    
	[super viewWillAppear: animated];
}

- (void) viewDidAppear:(BOOL)animated {
	[super viewDidAppear: animated];
    if ([gDelegateApp restartCount] == 0) {
        [self firstViewDidAppear];
	} else {
        [self restartedViewDidAppear];
    }
}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear: animated];
    [self forgetNotifications];
}

#pragma mark Notifications
- (void)listenNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidChange:)
												 name:UITextInputCurrentInputModeDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(softKeyboardDeactivate:)
												 name:@"SqueakUIViewTouchesBegan" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(softKeyboardDeactivate:)
												 name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scratchDialogOpened:)
												 name:@"ScratchDialogOpened" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scratchDialogClosed:)
												 name:@"ScratchDialogClosed" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scratchProjectReloaded:)
												 name:@"ScratchProjectReloaded" object:nil];
}

- (void)forgetNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextInputCurrentInputModeDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"SqueakUIViewTouchesBegan" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ScratchDialogOpened" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ScratchDialogClosed" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ScratchProjectReloaded" object:nil];
}


#pragma mark View Opening
- (void) firstViewDidAppear{
    [[self appDelegate] openDefaultProject];
}

- (void) restartedViewDidAppear{
    [SUYUtils inform:(NSLocalizedString(@"Done!",nil)) duration:400 for:self];
    [[self appDelegate] openDefaultProject];
}

- (void) postOpen {
    dispatch_async (
        dispatch_get_main_queue(),
        ^{
            [gDelegateApp terminateActivityView];
            [self fixOrientationIfNeeded];
        }
    );
}

#pragma mark Rotation
- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    if([self isInPresentationMode]){
        return UIInterfaceOrientationMaskAll;
    }
    return UIInterfaceOrientationMaskLandscape;
}

//- (UIInterfaceOrientation) preferredInterfaceOrientationForPresentation
//{
//    return UIInterfaceOrientationLandscapeLeft;
//}

-(void) viewDidLayoutSubviews{
    if([self isInPresentationMode]==NO){return;}
    [self fixLayoutByOrientation];
}

-(void)fixLayoutByOrientation{
    CGFloat ratio = 1.0f;
    CGPoint offsetPoint = self.scrollView.contentOffset;
    CGSize sz = [SUYUtils scratchScreenSize];
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if(_formerOrientation != orientation){
        if(UIInterfaceOrientationIsPortrait(orientation) && UIInterfaceOrientationIsLandscape(_formerOrientation)){
            ratio = sz.height/sz.width;
            _originalScrollerScale = _originalScrollerScale * ratio;
            self.scrollView.minimumZoomScale = ratio;
            [self.scrollView setZoomScale: _originalScrollerScale animated:YES];
            self.scrollView.contentOffset = CGPointMake(offsetPoint.x*ratio, offsetPoint.y*ratio);
            self.presentationExitButton.hidden = YES;
        }
        else if(UIInterfaceOrientationIsLandscape(orientation) && UIInterfaceOrientationIsPortrait(_formerOrientation)) {
            ratio = sz.width/sz.height;
            _originalScrollerScale = _originalScrollerScale * ratio;
            self.scrollView.minimumZoomScale = 1.0f;
            [self.scrollView setZoomScale: _originalScrollerScale animated:YES];
            self.scrollView.contentOffset = CGPointMake(offsetPoint.x*ratio, offsetPoint.y*ratio);
            self.presentationExitButton.hidden = NO;
        }
        _formerOrientation = orientation;
    }
}

-(void)fixOrientationIfNeeded{
    //MARK: NO-OP for now - forcing orientation is not good
    
//    if([self isInPresentationMode]){
//        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
//        if(UIInterfaceOrientationIsLandscape(orientation)==NO){
//            NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationLandscapeLeft];
//            [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
//            [self fixLayoutByOrientation];
//            [self exitPresentation: self];
//            LgInfo(@"!!! orientation changed");
//        }
//    }
}


#pragma mark - UIPopoverPresentationControllerDelegate

- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
    self.fontScaleButton.selected = NO;
}

#pragma mark - Actions


- (IBAction) openCamera:(NSString *)clientMode{
    SUYCameraViewController *viewController = [[SUYCameraViewController alloc] initWithNibName:@"SUYCameraViewController" bundle:nil];
    viewController.modalPresentationStyle = UIModalPresentationFormSheet;
    viewController.clientMode = clientMode;
    [self presentViewController:viewController animated:YES completion:NULL];
}

- (IBAction) openPhotoLibraryPicker:(NSString *)clientMode{
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"SUYPhotoPicker" bundle:[NSBundle mainBundle]];
    SUYPhotoPickViewController *viewController = (SUYPhotoPickViewController*)[storyboard instantiateInitialViewController];
    
    viewController.modalPresentationStyle = UIModalPresentationFormSheet;
    viewController.clientMode = clientMode;
    [self presentViewController:viewController animated:YES completion:NULL];
}

- (IBAction) openHelp:(NSString *)url {
    SUYWebViewController *viewController = [[SUYWebViewController alloc] initWithNibName:@"SUYWebViewController" bundle:nil];
    viewController.modalPresentationStyle = UIModalPresentationPageSheet;
    viewController.initialUrl = url;
    [self presentViewController:viewController animated:YES completion:NULL];
    
}

- (IBAction) showWaitIndicator {
    if(indicatorView != null){return;}
    indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    indicatorView.hidesWhenStopped = YES;
    [self.view addSubview:indicatorView];
    indicatorView.center = self.view.center;
    [indicatorView startAnimating];
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
}

- (IBAction) hideWaitIndicator {
    if(indicatorView == null){return;}
    [indicatorView stopAnimating];
    [indicatorView removeFromSuperview];
    indicatorView = nil;
    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
}


- (IBAction) openFontResizer:(id)sender {
    [SUYUtils hideCursor];
    if(self.viewModeIndex == 2){return;}
    
    self.fontScaleButton.selected = YES;
	SUYFontResizeViewController *fontResizeController = [[SUYFontResizeViewController alloc] initWithNibName:@"SUYFontResizeViewController" bundle:[NSBundle mainBundle]];
    
    fontResizeController.modalPresentationStyle = UIModalPresentationPopover;
    fontResizeController.preferredContentSize = CGSizeMake(320.0f,80.0f);
    
    UIPopoverPresentationController *presentationController = [fontResizeController popoverPresentationController];
    presentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    presentationController.sourceView = self.view;
    presentationController.sourceRect = self.fontScaleButton.frame;
    presentationController.delegate = self;
    
    [self presentViewController:fontResizeController animated: YES completion: nil];
    
}

- (IBAction) operatePadLock: (id) sender {
    [SUYUtils hideCursor];
	self.padLockButton.selected = !self.padLockButton.selected;
	self.scrollView.delaysContentTouches = self.padLockButton.selected;  // padlock is open (aka selected) so we delay
}

- (IBAction) shoutGo:(id)sender {
    [SUYUtils hideCursor];
	self.shoutGoLandscapeButton.selected = YES;
	self.stopAllLandscapeButton.selected = NO;
    dispatch_async (
        dispatch_get_main_queue(),
        ^{
           [[self appDelegate] shoutGo];
         }
    );
}

- (IBAction) stopAll:(id)sender {
    [SUYUtils hideCursor];
	self.shoutGoLandscapeButton.selected =  NO;
	self.stopAllLandscapeButton.selected = YES;
    
    dispatch_async (
        dispatch_get_main_queue(),
        ^{
           [[self appDelegate] stopAll];
        }
    );
}

- (IBAction) exitPresentation:(id)sender{
    [SUYUtils hideCursor];
    self.radioButtonSetController.selectedIndex = _originalEditModeIndex;
    self.presentationExitButton.hidden = YES;
    self.viewModeBar.hidden = NO;
    self.view.backgroundColor = _originalBackgroundColor;
    dispatch_async (
         dispatch_get_main_queue(),
         ^{
              [[self appDelegate] exitPresentationMode];
          }
    );
}

- (IBAction) softKeyboardActivate:(id)sender {
    [SUYUtils hideCursor];
    if(!self.softKeyboardField.hidden){return;}
    self.softKeyboardField.hidden = NO;
    [softKeyboardField becomeFirstResponder];
}

- (IBAction) softKeyboardDeactivate: (id) sender{
    if(self.softKeyboardField.hidden){return;}
    self.softKeyboardField.hidden = YES;
    [softKeyboardField resignFirstResponder];
}

- (IBAction) commandButtonUp:(id)sender {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(basicCommandButtonAutoUp:) object:sender];
    [self performSelector:@selector(basicCommandButtonAutoUp:) withObject:sender afterDelay: kCommandAutoUpSeconds];
}

- (IBAction) commandButtonDown:(id)sender {
    [SUYUtils hideCursor];
	self.commandButton.selected = YES;
	[[self appDelegate] commandKeyStateChanged: 1];
}

- (IBAction) basicCommandButtonAutoUp:(id)sender {
	self.commandButton.selected =  NO;
    [[self appDelegate] commandKeyStateChanged: 0];
}

- (IBAction) shiftButtonUp:(id)sender {
    if(self.shiftButton.selected == YES){
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(basicShiftButtonAutoUp:) object:sender];
        [self performSelector:@selector(basicShiftButtonAutoUp:) withObject:sender afterDelay: kShiftAutoUpSeconds];
    } else {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(basicShiftButtonAutoUp:) object:sender];
    }
}

- (IBAction) shiftButtonDown:(id)sender {
    [SUYUtils hideCursor];
	self.shiftButton.selected =  !self.shiftButton.selected;
	[[self appDelegate] shiftKeyStateChanged: shiftButton.selected];
}

- (IBAction) basicShiftButtonAutoUp:(id)sender {
    self.shiftButton.selected =  NO;
    LgInfo(@"!!! shiftButtonAutoUp !!!");
    [[self appDelegate] shiftKeyStateChanged: NO];
}

- (void) airDropProject: (NSString *)projectPath {
    [SUYUtils hideCursor];
    NSURL *url = [NSURL fileURLWithPath:projectPath];
    NSArray *objectsToShare = @[url];
    
    UIActivityViewController *activityVc = [[UIActivityViewController alloc] initWithActivityItems:objectsToShare applicationActivities:nil];
    
    // Exclude all activities except AirDrop.
//    NSArray *excludedActivities = @[UIActivityTypePostToTwitter, UIActivityTypePostToFacebook,
//                                    UIActivityTypePostToWeibo,
//                                    UIActivityTypeMessage, UIActivityTypeMail,
//                                    UIActivityTypePrint, UIActivityTypeCopyToPasteboard,
//                                    UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll,
//                                    UIActivityTypeAddToReadingList, UIActivityTypePostToFlickr,
//                                    UIActivityTypePostToVimeo, UIActivityTypePostToTencentWeibo];
//    activityVc.excludedActivityTypes = excludedActivities;
    
    activityVc.modalPresentationStyle = UIModalPresentationPopover;
    activityVc.preferredContentSize = CGSizeMake(320.0f,320.0f);
    
    UIPopoverPresentationController *presentationController = [activityVc popoverPresentationController];
    presentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    presentationController.sourceView = self.view;
    presentationController.sourceRect = CGRectMake(self.view.center.x-135,2,10,42);
    presentationController.delegate = self;
    
    [self presentViewController:activityVc animated: NO completion: nil];
}


- (void) exportToCloud: (NSString *)resourcePath{
    [SUYUtils hideCursor];
    NSDictionary *userInfo =  @{@"resourcePath": resourcePath};
    _exportResourceRetryCount = 0;
    [NSTimer scheduledTimerWithTimeInterval: 1.5 target: self selector:@selector(tickExportToCloud:) userInfo: userInfo repeats:YES];
}


- (void) tickExportToCloud: (NSTimer*) timer {
    NSDictionary *userInfo = timer.userInfo;
    NSString *resourcePath = (NSString*)userInfo[@"resourcePath"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:resourcePath] == NO){
        _exportResourceRetryCount = _exportResourceRetryCount + 1;
        if(_exportResourceRetryCount > 20){
            [timer invalidate];
        }
        return;
    }
    [timer invalidate];
    
    NSURL *url = [NSURL fileURLWithPath: resourcePath];
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initWithURL:url inMode:UIDocumentPickerModeExportToService];
    picker.delegate = self;
    [self presentViewController:picker animated:NO completion:nil];
    _lastExportResourcePath = resourcePath;
}

- (void) importFromCloud{
    [SUYUtils hideCursor];
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:[SUYUtils supportedUtis] inMode:UIDocumentPickerModeImport];
    picker.delegate = self;
    
    if(OVER_IOS10){
        return [self presentViewController:picker animated:NO completion:nil];
    }
    //FIXME: For iOS9 stability
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self presentViewController:picker animated:NO completion:nil];
    });
}

#pragma mark UIDocumentPickerDelegate
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url{
    if(controller.documentPickerMode == UIDocumentPickerModeImport){
        NSLog(@"IMPORT");
        [[self appDelegate] openImporting:url];
    }
    if(controller.documentPickerMode == UIDocumentPickerModeExportToService){
        NSLog(@"Export");
        if(_lastExportResourcePath){
            if([_lastExportResourcePath hasPrefix: [SUYUtils tempDirectory]]){
                [[NSFileManager defaultManager] removeItemAtPath:_lastExportResourcePath error:nil];
            }
        }
        [SUYUtils inform:(NSLocalizedString(@"Done!",nil)) duration:400 for:self];
    }
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller{
    LgInfo(@"Picker cancelled");
}


#pragma mark Accessing
- (int) viewModeIndex {
    return (int)self.radioButtonSetController.selectedIndex;
}

- (ScratchIPhoneAppDelegate*) appDelegate{
    return (ScratchIPhoneAppDelegate*) gDelegateApp;
}

#pragma mark Testing

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark Scrolling
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return gDelegateApp.mainView;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
    _originalScrollerScale = scale;
}

#pragma mark TextEdit

- (void)keyboardDidChange:(NSNotification*)sender{
    LgInfo(@"keyboardDidChange");
    self.softKeyboardField.text = @"";
    NSString *primLang = [self inputModePrimaryLanguage];
    
    if(
       ([primLang rangeOfString:@"ja-"].location != NSNotFound) ||
       ([primLang rangeOfString:@"ko-"].location != NSNotFound) ||
       ([primLang rangeOfString:@"zh-"].location != NSNotFound)) {
        LgInfo(@"ime mode = %@", primLang);
        self.softKeyboardField.autocorrectionType = UITextAutocorrectionTypeDefault;
        _useIme = YES;
    } else {
        LgInfo(@"non ime = %@", primLang);
        self.softKeyboardField.autocorrectionType = UITextAutocorrectionTypeNo;
        _useIme = NO;
    }
 }


- (BOOL)textFieldShouldBeginEditing:(UITextField *) aTextField {
    if(aTextField == self.softKeyboardField){
        aTextField.text = @"";
    }
    if(aTextField == self.textField){
        aTextField.text = @" ";
        characterCounter = 0;
    }
	return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField *) aTextField {
    if(aTextField == self.softKeyboardField){
        self.softKeyboardField.hidden = YES;
        [self flushInputString: self.softKeyboardField.text];
    }
    [aTextField resignFirstResponder];
    characterCounter = 0;
    
    if(aTextField == self.textField){
        aTextField.text = @" ";
    } else {
        aTextField.text = @"";
    }
	return YES;
}

-(void)flushInputString:(NSString*) processedString {
    if(_useIme == NO) {return;}
    LgInfo(@"!!! flushInputString %@", processedString);
    if(self.viewModeIndex==2){
        [[self appDelegate] flushInputString: processedString];
    }
    [gDelegateApp.mainView recordCharEvent: processedString];
}

- (BOOL)textField:(UITextField *) aTextField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)rstr {
	if(aTextField == self.textField){
        return [self nonImeTextField:aTextField shouldChangeCharactersInRange:range replacementString:rstr];
    }
    if(aTextField == self.softKeyboardField){
        if(_useIme == NO){
            [self nonImeTextField:aTextField shouldChangeCharactersInRange:range replacementString:rstr];
        }
        return YES;
    }
	return NO;
}

- (BOOL)nonImeTextField:(UITextField *) aTextField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)rstr {
    const unichar delete = 0x08;
	if ([rstr length] > 0 && [rstr characterAtIndex: 0] == (unichar) 10) {
		[aTextField resignFirstResponder];
		aTextField.text = @"";
		[gDelegateApp.mainView recordCharEvent: rstr];
		return NO;
	}
	if ([rstr length] == 0) {
		
		[gDelegateApp.mainView recordCharEvent: [NSString stringWithCharacters: &delete length: 1] ];
	} else {
        if(range.length > 0){
            //[gDelegateApp.mainView recordCharEvent: rstr]; //TODO: fix previous text
        } else {
            [gDelegateApp.mainView recordCharEvent: rstr];
        }
	}
    return NO;
}


- (void) textMorphFocused: (BOOL)status{
    if((status == YES) && (softKeyboardField.hidden))
    {
        [self performSelectorOnMainThread:@selector(softKeyboardActivate:) withObject: nil waitUntilDone: NO];
    }
}

- (NSString *)inputModePrimaryLanguage {
    UITextInputMode *inputMode = self.textInputMode;
    if(inputMode == nil){ return @"";}
    NSString *primLang = [inputMode primaryLanguage];
    return primLang;
}

#pragma mark Key Handling

- (void) pushCharacter: (NSString*) string {
	[gDelegateApp.mainView recordCharEvent: string];
}

- (void)repeatKeyDoKey:(NSTimer*)theTimer {
	[self pushCharacter: [[theTimer userInfo] string]];
}

- (void)repeatKeySecondPhase:(NSTimer*)theTimer {
	[self repeatKeyDoKey: theTimer];
	NSNumber *senderHash = [[theTimer userInfo] senderHash];
	@synchronized(self) {
		NSTimer *newTimer = [NSTimer scheduledTimerWithTimeInterval:0.05f target:self 
															 selector:@selector(repeatKeyDoKey:) 
												  userInfo: [theTimer userInfo] repeats:YES];
		[self.repeatKeyDict removeObjectForKey: senderHash];
		[self.repeatKeyDict setObject:newTimer forKey: senderHash];
	}
}

- (void) startRepeatKeyAction: (NSString*) string  for: (id) sender {
	@synchronized(self) {
		ScratchRepeatKeyMetaData *stub = [[ScratchRepeatKeyMetaData alloc] init];
		stub.string = string;
		stub.senderHash = [NSNumber numberWithUnsignedInteger:[sender hash]] ;
		NSTimer *repeatKeyTimerInstance = [NSTimer scheduledTimerWithTimeInterval:0.2f target:self 
															 selector:@selector(repeatKeySecondPhase:) 
											  userInfo: stub repeats:NO];
		[self.repeatKeyDict setObject:repeatKeyTimerInstance forKey: stub.senderHash];
	}
}

- (IBAction) keySpace: (id) sender {
    
    if(self.commandButton.selected == YES) {
        [self keyEnter:sender];
        return;
    }
    
	BOOL spaceRepeats = [(sqSqueakIPhoneInfoPlistInterface*) gDelegateApp.squeakApplication.infoPlistInterfaceLogic spaceRepeats];
	if (spaceRepeats) {
		unichar character = 32;
		[self startRepeatKeyProcess: character for: sender];
	} else {
		[self pushCharacter: @" "];
	}
}

- (IBAction) keyTouchUp:(id)sender {
    [SUYUtils hideCursor];
    LgInfo(@"HIDE cursor");
	@synchronized(self) {
		NSNumber *senderHash = [NSNumber numberWithUnsignedInteger:[sender hash]];
		NSTimer *repeatKeyTimerInstance = [self.repeatKeyDict objectForKey: senderHash];
		if (repeatKeyTimerInstance) {
			[repeatKeyTimerInstance invalidate];
			[self.repeatKeyDict removeObjectForKey: senderHash];
		}
	}
}

- (IBAction) keyEnter: (id) sender {
    [self pushCharacter: [NSString stringWithFormat:@"%c", 13]];
}


- (void) startRepeatKeyProcess: (unichar) character for: (id) sender {
	NSString *string = [[NSString alloc] initWithCharacters:&character length: 1];
	[self pushCharacter: string];
	[self startRepeatKeyAction: string for: sender];
}

- (IBAction) keyUpArrow:(id)sender {
	unichar character = 30;
	[self startRepeatKeyProcess: character for: sender];
}

- (IBAction) keyDownArrow:(id)sender {
	unichar character = 31;
	[self startRepeatKeyProcess: character for: sender];
}

- (IBAction) keyLeftArrow:(id)sender {
	unichar character = 28;
	[self startRepeatKeyProcess: character for: sender];
}

- (IBAction) keyRightArrow:(id)sender {
	unichar character = 29;
	[self startRepeatKeyProcess: character for: sender];
}

#pragma mark View Mode
- (void)changedViewModeIndex:(NSUInteger)selectedIndex
{
    [SUYUtils hideCursor];
    if(selectedIndex <= 1){
        _originalEditModeIndex = selectedIndex;
        self.scrollView.backgroundColor = _originalBackgroundColor;
        self.view.backgroundColor = _originalBackgroundColor;
    } else {
        self.presentationExitButton.hidden = NO;
        self.viewModeBar.hidden = YES;
        self.scrollView.backgroundColor = [UIColor blackColor];
        self.view.backgroundColor = [UIColor blackColor];
    }
}

- (void)radioButtonSetController:(GSRadioButtonSetController *)controller didSelectButtonAtIndex:(NSUInteger)selectedIndex
{
    [self changedViewModeIndex:selectedIndex];
    [self setViewModeIndex:(int)selectedIndex];
}

- (void)setViewModeIndex:(int)selectedIndex
{
    dispatch_async (
          dispatch_get_main_queue(),
           ^{
               [[self appDelegate] setViewModeIndex: selectedIndex];
            }
    );
    
}

- (BOOL) isViewModeBarHidden
{
    return self.viewModeBar.hidden;
}

- (BOOL) isInPresentationMode
{
    return [self isViewModeBarHidden] && self.viewModeIndex == 2;
}

#pragma mark Callback from Scratch

- (void)scratchDialogOpened:(id)sender
{
    dispatch_async (
         dispatch_get_main_queue(),
         ^{
             [UIView transitionWithView:self.viewModeBar
                               duration:0.6
                                options:UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionAllowUserInteraction
                             animations:NULL
                             completion:NULL];
             self.viewModeBar.hidden = YES;
          }
    );
}

- (void)scratchDialogClosed:(id)sender
{
    dispatch_async (
        dispatch_get_main_queue(),
        ^{
            self.viewModeBar.alpha = 0;
            self.viewModeBar.hidden = NO;
            [UIView animateWithDuration:0.3 animations:^{
                self.viewModeBar.alpha = 1;
            }];
        }
    );
}

-(void) scratchProjectReloaded:(id)sender
{
    dispatch_async (
        dispatch_get_main_queue(),
        ^{
            [self changedViewModeIndex:[[self appDelegate] getViewModeIndex]];
        }
    );
}


#pragma mark Releasing

- (void)dealloc {
	@synchronized(self) {
		for (NSTimer *e in [self.repeatKeyDict allValues]) {
			[e invalidate];
		}
	}
}

- (void)didReceiveMemoryWarning {
    memoryWarningCount++;
    
	[super didReceiveMemoryWarning];
    
    int bytesLeft = [gDelegateApp squeakMemoryBytesLeft];
    LgInfo(@"  --- SqueakMemoryBytesLeft: %d", bytesLeft);
    LgInfo(@"  --- warningMinHeapThreshold: %d", warningMinHeapThreshold);
    LgInfo(@"$$$ RestartCount:%d", [[self appDelegate] restartCount]);
    
    int minCount = 2 - [[self appDelegate] restartCount];
    if(minCount <= 0){minCount = 1;}
    
    if(memoryWarningCount > minCount){
       LgInfo(@"$$$ - memoryWarningCount restart");
       [[self appDelegate] restartVm];
    } else if(warningMinHeapThreshold > bytesLeft){
       LgInfo(@"$$$ - warningHeapThreshold restart");
       [[self appDelegate] restartVm];
    } else {
        LgInfo(@"$$$ - ignored memory warning...");
    }

}


@end
