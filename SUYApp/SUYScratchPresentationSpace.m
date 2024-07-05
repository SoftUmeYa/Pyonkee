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
    
    CGFloat _formerScratchScreenZoomScale;
    
    NSMutableArray* _keyCommands;
}

@synthesize scrollView,scrollViewController,fontScaleButton, radioButtonSetController,
	textField,repeatKeyDict,repeatExternalKeyDict,
    softKeyboardField, softKeyboardOnButton,
	shoutGoLandscapeButton,stopAllLandscapeButton,landscapeToolBar,landscapeToolBar2,padLockButton,
    commandButton, shiftButton,
	indicatorView, viewModeBar, presentationExitButton,
    scrollViewHeightConstraint, modeBarLeadingConstraint, modeBarWidthConstraint;


uint warningMinHeapThreshold;
uint memoryWarningCount;

#pragma mark Initialization
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        repeatKeyDict = [[NSMutableDictionary alloc] init];
        repeatExternalKeyDict = [[NSMutableDictionary alloc] init];
	}
    return self;
}


#pragma mark View Callback
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    _useIme = NO;
    
    [self adjustConstraintsOnViewLoad];
    
    self.textField.keyboardAppearance = UIKeyboardAppearanceAlert;
    self.softKeyboardField.hidden = YES;
	 
	[self.scrollView addSubview: gDelegateApp.mainView];
    self.scrollView.contentSize = gDelegateApp.mainView.bounds.size;
    
    self.viewModeBar.layer.cornerRadius = 5;
    self.viewModeBar.layer.masksToBounds = YES;
    
    _originalScrollerScale = SUYUtils.scratchScreenZoomScale;
    [self.scrollView setZoomScale: _originalScrollerScale animated: NO];
    self.scrollView.minimumZoomScale = SUYUtils.scratchScreenZoomScale;
    self.scrollView.maximumZoomScale = 8;
    [self.scrollView flashScrollIndicators];
    
    if(SUYUtils.isOnMac){
        self.scrollView.scrollEnabled = NO;
        self.padLockButton.hidden = YES;
        //self.viewModeBar.hidden = YES;
    }
    
    _originalBackgroundColor = self.view.backgroundColor;
    _originalEditModeIndex = 1;
    
    warningMinHeapThreshold = [gDelegateApp squeakMaxHeapSize] * 0.70;
    memoryWarningCount = 0;
    
    _formerOrientation = SUYUtils.interfaceOrientation;
    
}

- (void) viewWillAppear:(BOOL)animated {
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible: NO];
	[gDelegateApp.viewController setNavigationBarHidden: YES animated: YES];
	
	self.scrollView.delaysContentTouches = self.padLockButton.selected;
    self.radioButtonSetController.selectedIndex = _originalEditModeIndex;
    [self setKeyboardProperties];
    [self listenNotifications];
    
	[super viewWillAppear: animated];
}

- (void) viewDidAppear:(BOOL)animated {
	[super viewDidAppear: animated];
    if(SUYUtils.isOnMac){
        self.scrollView.showsHorizontalScrollIndicator = NO;
        self.scrollView.showsVerticalScrollIndicator = NO;
    }
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
    NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
    if(!SUYUtils.isOnMac){
        [notificationCenter addObserver:self selector:@selector(keyboardDidShow:)
                                                     name:UIKeyboardDidShowNotification object:nil];
        [notificationCenter addObserver:self selector:@selector(keyboardDeactivate:)
                                                     name:UIKeyboardWillHideNotification object:nil];
    }
    [notificationCenter addObserver:self selector:@selector(keyboardDidChange:)
                                                 name:UITextInputCurrentInputModeDidChangeNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(keyboardDeactivate:)
                                                 name:@"SqueakUIViewTouchesBegan" object:nil];
    [notificationCenter addObserver:self selector:@selector(scratchDialogOpened:)
                                                 name:@"ScratchDialogOpened" object:nil];
    [notificationCenter addObserver:self selector:@selector(scratchDialogClosed:)
                                                 name:@"ScratchDialogClosed" object:nil];
    [notificationCenter addObserver:self selector:@selector(scratchProjectReloaded:)
                                                 name:@"ScratchProjectReloaded" object:nil];
    [notificationCenter addObserver:self selector:@selector(meshEnabledProjectLoaded:)
                                                 name:@"MeshEnabledProjectLoaded" object:nil];
}

- (void)forgetNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextInputCurrentInputModeDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"SqueakUIViewTouchesBegan" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ScratchDialogOpened" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ScratchDialogClosed" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ScratchProjectReloaded" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"MeshEnabledProjectLoaded" object:nil];
}


#pragma mark View Opening
- (void) firstViewDidAppear{
    [[self appDelegate] openDefaultProject];
}

- (void) restartedViewDidAppear{
    [SUYUtils inform:(NSLocalizedString(@"Done!",nil)) duration:400];
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

- (void)adjustConstraintsOnViewLoad {
    scrollViewHeightConstraint.constant = SUYUtils.landscapeScreenHeight;
    [self fixModebarConstraints];
}

#pragma mark Rotation
- (BOOL)shouldAutorotate {
    return YES;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize: size withTransitionCoordinator: coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        UIInterfaceOrientation orientation = SUYUtils.interfaceOrientation;
        [self appDelegate].sensorAccessor.currentInterfaceOrientation = orientation;
    }];
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
    if(SUYUtils.isOnMac){
        [self fixLayoutOfSubViews];
    }
    if([self isInPresentationMode]==NO){return;}
    [self fixLayoutByOrientation];
}

-(void)fixLayoutByOrientation{
    CGPoint offsetPoint = self.scrollView.contentOffset;
    CGSize sz = [SUYUtils scratchScreenSize];
    
    UIInterfaceOrientation orientation = SUYUtils.interfaceOrientation;
    if(_formerOrientation != orientation){
        if(UIInterfaceOrientationIsPortrait(orientation) && UIInterfaceOrientationIsLandscape(_formerOrientation)){
            CGFloat aspectRatio = sz.width/sz.height;
            CGFloat newHeight = SUYUtils.landscapeScreenHeight / aspectRatio;
            scrollViewHeightConstraint.constant = newHeight;
            CGFloat realComputedScale = newHeight / SUYUtils.landscapeScreenHeight;
            _originalScrollerScale = _originalScrollerScale * realComputedScale;
            self.scrollView.minimumZoomScale = SUYUtils.scratchScreenZoomScale * realComputedScale;
            [self.scrollView setZoomScale: _originalScrollerScale animated:YES];
            self.scrollView.contentOffset = CGPointMake(offsetPoint.x * realComputedScale, offsetPoint.y * realComputedScale);
            self.presentationExitButton.hidden = YES;
        }
        else if(UIInterfaceOrientationIsLandscape(orientation) && UIInterfaceOrientationIsPortrait(_formerOrientation)) {
            CGFloat oldHeight = scrollViewHeightConstraint.constant;
            CGFloat realComputedScale = SUYUtils.landscapeScreenHeight / oldHeight;
            scrollViewHeightConstraint.constant = SUYUtils.landscapeScreenHeight;
            _originalScrollerScale = _originalScrollerScale * realComputedScale;
            self.scrollView.minimumZoomScale = SUYUtils.scratchScreenZoomScale;
            [self.scrollView setZoomScale: _originalScrollerScale animated:YES];
            self.scrollView.contentOffset = CGPointMake(offsetPoint.x * realComputedScale, offsetPoint.y * realComputedScale);
            self.presentationExitButton.hidden = NO;
        }
        _formerOrientation = orientation;
    }
}

-(void)fixOrientationIfNeeded{
    //MARK: NO-OP for now - forcing orientation is not good
    
//    if([self isInPresentationMode]){
//        UIInterfaceOrientation orientation = SUYUtils.interfaceOrientation;
//        if(UIInterfaceOrientationIsLandscape(orientation)==NO){
//            NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationLandscapeLeft];
//            [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
//            [self fixLayoutByOrientation];
//            [self exitPresentation: self];
//            LgInfo(@"!!! orientation changed");
//        }
//    }
}

#pragma mark - Layout for Mac

-(void) fixLayoutOfSubViews {
    if(self.presentedViewController){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 100 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
            [[self appDelegate] restoreDisplayIfNeeded];
        });
    }
}

#pragma mark - Resizing for Mac

-(void)fixLayoutOnWindowResizing{
    [self fixSizeOfSubViewsIfNeeded];
}

- (void)fixSizeOfSubViewsIfNeeded {
    if(!SUYUtils.isOnMac) return;
    CGFloat scale = SUYUtils.scratchScreenZoomScale;
    if(_formerScratchScreenZoomScale == scale) {
        return;
    }
    scrollViewHeightConstraint.constant = SUYUtils.landscapeScreenHeight;
    [self.scrollView setZoomScale: scale animated:YES];
    self.scrollView.contentOffset = CGPointMake(0, 0);
    [self fixModebarConstraints];
    _formerScratchScreenZoomScale = scale;
}

#pragma mark - Fixing layout constraints

-(void)fixModebarConstraints{
    CGFloat ratio = SUYUtils.scratchScreenZoomScale;
    modeBarLeadingConstraint.constant = 350 * ratio;
    modeBarWidthConstraint.constant = 150 * ratio;
}

#pragma mark - UIPopoverPresentationControllerDelegate

- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
    self.fontScaleButton.selected = NO;
}

#pragma mark - Actions


- (IBAction) openCamera:(NSString *)clientMode{
    SUYCameraViewController *viewController = [[SUYCameraViewController alloc] initWithNibName:@"SUYCameraViewController" bundle:nil];
    viewController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    viewController.clientMode = clientMode;
    [self presentViewController:viewController animated:YES completion:NULL];
}

- (IBAction) openPhotoLibraryPicker:(NSString *)clientMode{
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"SUYPhotoPicker" bundle:[NSBundle mainBundle]];
    SUYPhotoPickViewController *viewController = (SUYPhotoPickViewController*)[storyboard instantiateInitialViewController];
    
    viewController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    viewController.clientMode = clientMode;
    [self presentViewController:viewController animated:YES completion:NULL];
}

- (IBAction) openHelp:(NSString *)url {
    SUYWebViewController *viewController = [[SUYWebViewController alloc] initWithNibName:@"SUYWebViewController" bundle:nil];
    viewController.modalPresentationStyle = UIModalPresentationOverFullScreen;
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
    if(self.isPresentationButtonOn){return;}
    
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
             [self ensureSupportedInterfaceOrientationsChecked];
          }
    );
}

- (IBAction) keyboardActivate:(id)sender {
    [SUYUtils hideCursor];
    if(self.softKeyboardIsActivated){return;}
    self.softKeyboardField.hidden = NO;
    [softKeyboardField becomeFirstResponder];
    if(SUYUtils.isOnMac){
        _useIme = [self detectImeIsUsed];
    }
}

- (IBAction) keyboardDeactivate: (id) sender{
    if(!self.softKeyboardIsActivated){return;}
    self.softKeyboardField.hidden = YES;
    [softKeyboardField resignFirstResponder];
    [self refocusIfNeeded];
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
    
    return [self presentViewController:picker animated:NO completion:nil];
}

- (void) openMeshDialog {
    if (@available(iOS 14.0, *)) {
        UIViewController *vc = [MeshUIViewFactory makeMeshUiViewControllerWithDismissHandler:^{
            [[self presentedViewController] dismissViewControllerAnimated:YES completion:^{
                [self fixSizeOfSubViewsIfNeeded];
            }];
        }];
        vc.modalPresentationStyle = UIModalPresentationFormSheet;
        vc.preferredContentSize = CGSizeMake(400, 295);
        [self presentViewController:vc animated:YES completion:nil];
    }
}

#pragma mark UIDocumentPickerDelegate
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray <NSURL *>*)urls{
    NSURL* url = urls[0];
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
        [SUYUtils inform:(NSLocalizedString(@"Done!",nil)) duration:400];
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

- (BOOL)softKeyboardIsActivated
{
    return !self.softKeyboardField.hidden;
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

#pragma mark - UITextFieldDelegate

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
        [self flushInputString: aTextField.text];
        [self refocusIfNeeded];
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

#pragma mark TextEdit

- (void)keyboardDidShow:(NSNotification*)sender {
    self.softKeyboardField.text = @"";
    [self setKeyboardProperties];
}

- (void)keyboardDidChange:(NSNotification*)sender {
    [self setKeyboardProperties];
}

- (void) setKeyboardProperties {
    if([self detectImeIsUsed]) {
        self.softKeyboardField.autocorrectionType = UITextAutocorrectionTypeDefault;
        _useIme = YES;
    } else {
        self.softKeyboardField.autocorrectionType = UITextAutocorrectionTypeNo;
        _useIme = NO;
    }
}

-(void)flushInputString:(NSString*) processedString {
    if(_useIme == NO) {return;}
    LgInfo(@"!!! flushInputString %@", processedString);
    if(self.viewModeIndex==2){
        [[self appDelegate] flushInputString: processedString];
    }
    [gDelegateApp.mainView recordCharEvent: processedString];
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
        [self performSelectorOnMainThread:@selector(keyboardActivate:) withObject: nil waitUntilDone: NO];
    }
}

- (NSString *)inputModePrimaryLanguage {
    UITextInputMode *inputMode = self.textInputMode;
    if(inputMode == nil){ return @"";}
    NSString *primLang = [inputMode primaryLanguage];
    return primLang;
}

- (BOOL)detectImeIsUsed {
    NSString *primLang = [self inputModePrimaryLanguage];
    LgInfo(@"ime mode = %@", primLang);
    if(
       ([primLang rangeOfString:@"ja-"].location != NSNotFound) ||
       ([primLang rangeOfString:@"ko-"].location != NSNotFound) ||
       ([primLang rangeOfString:@"zh-"].location != NSNotFound)) {
           return YES;
    }
    return NO;
 }

- (void) refocusIfNeeded {
    if(SUYUtils.isOnMac){
        [self.textField becomeFirstResponder];
        [self becomeFirstResponder];
    }
}

#pragma mark Key Handling

- (void) pushCharacters: (NSString*) string {
	[gDelegateApp.mainView recordCharEvent: string];
}
- (void) pushCharacters: (NSString*) string modifiers: (unsigned int) modifiers autoKeyUp: (BOOL) autoKeyUp {
    [gDelegateApp.mainView recordCharEvent: string modifiers: modifiers autoKeyUp: autoKeyUp];
}

- (void)repeatKeyDoKey:(NSTimer*)theTimer {
	[self pushCharacters: [[theTimer userInfo] string] modifiers: 0 autoKeyUp: NO];
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
		[self pushCharacters: @" "];
	}
}

- (IBAction) keyTouchUp:(id)sender {
    [SUYUtils hideCursor];
    LgInfo(@"HIDE cursor");
	@synchronized(self) {
		NSNumber *senderHash = [NSNumber numberWithUnsignedInteger:[sender hash]];
		NSTimer *repeatKeyTimerInstance = [self.repeatKeyDict objectForKey: senderHash];
		if (repeatKeyTimerInstance) {
            [gDelegateApp.mainView recordKeyUpEvent: [repeatKeyTimerInstance.userInfo string]];
			[repeatKeyTimerInstance invalidate];
			[self.repeatKeyDict removeObjectForKey: senderHash];
		}
	}
}

- (IBAction) keyEnter: (id) sender {
    [self pushCharacters: [NSString stringWithFormat:@"%c", 13]];
}

- (void) startRepeatKeyProcess: (unichar) character for: (id) sender {
	NSString *string = [[NSString alloc] initWithCharacters:&character length: 1];
	[self pushCharacters: string];
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

#pragma mark Physical Key Press Handing
- (void)pressesBegan:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event {
    if (@available(iOS 13.4, *)) {
        if([self hasCharactersIn: presses]) return [super pressesBegan:presses withEvent:event];
        if ((event.modifierFlags & UIKeyModifierShift) == UIKeyModifierShift) {
            return [self externalKeyboardShiftDown];
        }
        if ((event.modifierFlags & UIKeyModifierCommand) == UIKeyModifierCommand) {
            return [self externalKeyboardCommandDown];
        }
    }
    [super pressesBegan:presses withEvent:event];
}

- (void)pressesEnded:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event {
    if (@available(iOS 13.4, *)) {
        if([self hasCharactersIn: presses]) return [super pressesBegan:presses withEvent:event];
        UIPress * pres = presses.anyObject;
        UIKeyboardHIDUsage keyCode = pres.key.keyCode;
        if (keyCode == UIKeyboardHIDUsageKeyboardLeftShift || keyCode == UIKeyboardHIDUsageKeyboardRightShift) {
            return [self externalKeyboardShiftUp];
        }
        if (keyCode == UIKeyboardHIDUsageKeyboardLeftGUI || keyCode == UIKeyboardHIDUsageKeyboardRightGUI) { //Command keys
            return [self externalKeyboardCommandUp];
        }
    }
    [super pressesEnded:presses withEvent:event];
}

- (BOOL) hasCharactersIn: (NSSet<UIPress *> *) presses
{
    NSSet<UIPress *> * charPresses = [presses objectsPassingTest:^(id obj, BOOL *stop){
        UIPress *press = (UIPress *)obj;
        BOOL hasCharacters = (press.key.characters.length >= 1);
        return hasCharacters;
    }];
    return charPresses.count > 0;
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
               [self ensureSupportedInterfaceOrientationsChecked];
            }
    );
}

- (BOOL) isViewModeBarHidden
{
    return self.viewModeBar.hidden;
}

- (BOOL) isInPresentationMode
{
    return [self isViewModeBarHidden] && self.isPresentationButtonOn;
}

- (BOOL) isPresentationButtonOn
{
    return self.viewModeIndex == 2;
}

- (void) ensureSupportedInterfaceOrientationsChecked
{
    if(OVER_IOS16){
        UIViewController *dummyViewController = [[UIViewController alloc] init];
        [dummyViewController setModalPresentationStyle: UIModalPresentationCustom];
        dummyViewController.view.frame = CGRectMake(0, 0, 1, 1);
        dummyViewController.view.backgroundColor = [UIColor clearColor];
        [self presentViewController:dummyViewController animated:NO completion:^{}];
        [self dismissViewControllerAnimated:NO completion:nil];
    }
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

-(void) meshEnabledProjectLoaded:(id)sender
{
    dispatch_async (
        dispatch_get_main_queue(),
        ^{
            if (@available(iOS 13.0, *)) {
                [MeshServiceAccessor meshEnabledProjectLoaded];
            }
        }
    );
}

#pragma mark Shortcut keys

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (NSArray *) keyCommands
{
    if(self.softKeyboardIsActivated) {
        return @[];
    }
    if(!_keyCommands){
        _keyCommands = [[NSMutableArray alloc] init];
        //arrow keys
        [self addKeyCommand:UIKeyInputUpArrow modifierFlags:kNilOptions action:@selector(externalKeyboardUpArrow:)
             overrideSystem:YES to: _keyCommands];
        [self addKeyCommand:UIKeyInputDownArrow modifierFlags:kNilOptions action:@selector(externalKeyboardDownArrow:)
             overrideSystem:YES to: _keyCommands];
        [self addKeyCommand:UIKeyInputLeftArrow modifierFlags:kNilOptions action:@selector(externalKeyboardLeftArrow:)
             overrideSystem:YES to: _keyCommands];
        [self addKeyCommand:UIKeyInputRightArrow modifierFlags:kNilOptions action:@selector(externalKeyboardRightArrow:)
             overrideSystem:YES to: _keyCommands];
        //escape
        [self addKeyCommand:UIKeyInputEscape modifierFlags:kNilOptions action:@selector(externalKeyboardEscape:)
             overrideSystem:NO to: _keyCommands];
        //space
        [self addKeyCommand:@" " modifierFlags:kNilOptions action:@selector(externalKeyboardSpace:)
             overrideSystem:NO to: _keyCommands];
        //backscape
        if (OVER_IOS15) {
            [self addKeyCommand:UIKeyInputDelete modifierFlags:kNilOptions action:@selector(externalKeyboardBackspace:)
                 overrideSystem:NO to: _keyCommands];
        }
        //enter
        [self addKeyCommand:@"\r" modifierFlags:kNilOptions action:@selector(externalKeyboardGeneric:)
             overrideSystem:NO to: _keyCommands];
        //tab
        [self addKeyCommand:@"\t" modifierFlags:kNilOptions action:@selector(externalKeyboardTab:)
             overrideSystem:YES to: _keyCommands];
        [self addKeyCommand:@" " modifierFlags:UIKeyModifierShift action:@selector(externalKeyboardTab:)
             overrideSystem:NO to: _keyCommands];
        
        //shift-only & cmd-only
        if (BEFORE_IOS13) {
            [self addKeyCommand:@"" modifierFlags:UIKeyModifierShift action:@selector(externalKeyboardShift:)
                 overrideSystem:NO to: _keyCommands];
            [self addKeyCommand:@"" modifierFlags:UIKeyModifierCommand action:@selector(externalKeyboardCommand:)
                 overrideSystem:NO to: _keyCommands];
        }
        
        [self addAlphNumericKeyCommandsTo: _keyCommands];
        
        [self addSymbolKeyCommandsTo: _keyCommands];
        
        if([[self appDelegate] isOnDevelopment]){
            [self addDevelopmentKeyCommandsTo: _keyCommands];
        }
        
    }
    return _keyCommands;
}

- (void) addKeyCommand: (NSString *)input modifierFlags:(UIKeyModifierFlags)modifierFlags action:(SEL)action overrideSystem:(BOOL) overrideSystem to:(NSMutableArray *) keyCommands {
    UIKeyCommand* command = [UIKeyCommand keyCommandWithInput:input modifierFlags:modifierFlags action:action];
    if (OVER_IOS15) {
        command.wantsPriorityOverSystemBehavior = overrideSystem;
    }
    [keyCommands addObject: command];
}

- (void) addAlphNumericKeyCommandsTo: (NSMutableArray <UIKeyCommand *>*)keyCommands
{
    NSString * numericKeys = @"0123456789";
    [numericKeys enumerateSubstringsInRange:NSMakeRange(0, numericKeys.length)
                              options:NSStringEnumerationByComposedCharacterSequences
                           usingBlock:^(NSString *keyString, NSRange substringRange,
                                        NSRange enclosingRange, BOOL *stop)
    {
        [self addKeyCommand:keyString modifierFlags:kNilOptions action:@selector(externalKeyboardGeneric:)
             overrideSystem:NO to: keyCommands];
    }];
    
    NSString * keys = @"abcdefghijklmnopqrstuvwxyz";
    [keys enumerateSubstringsInRange:NSMakeRange(0, keys.length)
                              options:NSStringEnumerationByComposedCharacterSequences
                           usingBlock:^(NSString *keyString, NSRange substringRange,
                                        NSRange enclosingRange, BOOL *stop)
    {
        [self addKeyCommand:keyString modifierFlags:kNilOptions action:@selector(externalKeyboardGeneric:)
             overrideSystem:NO to: keyCommands];
        [self addKeyCommand:[keyString uppercaseString] modifierFlags:UIKeyModifierShift action:@selector(externalKeyboardGeneric:)
             overrideSystem:NO to: keyCommands];
    }];
    
}

- (void) addSymbolKeyCommandsTo: (NSMutableArray <UIKeyCommand *>*)keyCommands
{
    NSString * numericKeys = @"!\"#$%&'()*+,-./:;<=>?@[]^_`{|}~";
    [numericKeys enumerateSubstringsInRange:NSMakeRange(0, numericKeys.length)
                              options:NSStringEnumerationByComposedCharacterSequences
                           usingBlock:^(NSString *keyString, NSRange substringRange,
                                        NSRange enclosingRange, BOOL *stop)
    {
        [self addKeyCommand:keyString modifierFlags:kNilOptions action:@selector(externalKeyboardGeneric:)
             overrideSystem:NO to: keyCommands];
    }];
    
    [self addKeyCommand: @"\\" modifierFlags:kNilOptions action:@selector(externalKeyboardGeneric:)
         overrideSystem:NO to: _keyCommands];
}

- (void) addDevelopmentKeyCommandsTo: (NSMutableArray <UIKeyCommand *>*)keyCommands
{
    NSString * shortcutKeys = @"azxcvdpibs";
    [shortcutKeys enumerateSubstringsInRange:NSMakeRange(0, shortcutKeys.length)
                              options:NSStringEnumerationByComposedCharacterSequences
                           usingBlock:^(NSString *keyString, NSRange substringRange,
                                        NSRange enclosingRange, BOOL *stop)
    {
        [self addKeyCommand:keyString modifierFlags:UIKeyModifierCommand action:@selector(externalKeyboardKeyCommandPressed:)
             overrideSystem:NO to: keyCommands];
    }];
    [self addKeyCommand: @"m" modifierFlags:UIKeyModifierCommand | UIKeyModifierShift action:@selector(externalKeyboardKeyCommandPressed:)
         overrideSystem:YES to: _keyCommands];
}

- (void) externalKeyboardUpArrow: (UIKeyCommand *) keyCommand
{
    NSString *input = [NSString stringWithFormat:@"%C", (unichar)30];
    [self externalKeyboardDownWithInput: input];
}

- (void) externalKeyboardDownArrow: (UIKeyCommand *) keyCommand
{
    NSString *input = [NSString stringWithFormat:@"%C", (unichar)31];
    [self externalKeyboardDownWithInput: input];
}

- (void) externalKeyboardLeftArrow: (UIKeyCommand *) keyCommand
{
    NSString *input = [NSString stringWithFormat:@"%C", (unichar)28];
    [self externalKeyboardDownWithInput: input];
}

- (void) externalKeyboardRightArrow: (UIKeyCommand *) keyCommand
{
    NSString *input = [NSString stringWithFormat:@"%C", (unichar)29];
    [self externalKeyboardDownWithInput: input];
}

- (void) externalKeyboardEscape: (UIKeyCommand *) keyCommand
{
    //Specific handling on presentation mode
    UIInterfaceOrientation orientation = SUYUtils.interfaceOrientation;
    if((self.isPresentationButtonOn)){
        if((UIInterfaceOrientationIsPortrait(orientation))){
            return;
        } else {
            return [self exitPresentation: self];
        }
    }
    
    unichar character = 27;
    [self startRepeatKeyProcess: character for: self];
    [self keyTouchUp:self];
}

- (void) externalKeyboardTab: (UIKeyCommand *) keyCommand
{
    unichar character = 9;
    [self startRepeatKeyProcess: character for: self];
    [self keyTouchUp:self];
}

- (void) externalKeyboardSpace: (UIKeyCommand *) keyCommand
{
    [self externalKeyboardDown: keyCommand];
}

- (void) externalKeyboardBackspace: (UIKeyCommand *) keyCommand
{
    unichar character = 8;
    [self startRepeatKeyProcess: character for: self];
    [self keyTouchUp:self];
}

- (void) externalKeyboardShiftDown
{
    [SUYUtils hideCursor];
    self.shiftButton.selected =  YES;
    [[self appDelegate] shiftKeyStateChanged: YES];
}
- (void) externalKeyboardShiftUp
{
    [SUYUtils hideCursor];
    self.shiftButton.selected =  NO;
    [[self appDelegate] shiftKeyStateChanged: NO];
}
- (void) externalKeyboardCommandDown
{
    [self commandButtonDown:self];
}
- (void) externalKeyboardCommandUp
{
    [self basicCommandButtonAutoUp:self];
}

#pragma mark Shortcut keys - obsolete

- (void) externalKeyboardShift: (UIKeyCommand *) keyCommand
{
    [self shiftButtonDown:self];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self basicShiftButtonAutoUp:self];
    });
}
- (void) externalKeyboardCommand: (UIKeyCommand *) keyCommand
{
    [self commandButtonDown:self];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self basicCommandButtonAutoUp:self];
    });
}

#pragma mark Key handling helpers

- (void) externalKeyboardDown: (UIKeyCommand *) keyCommand {
    NSString* input = keyCommand.input;
    [self externalKeyboardDownWithInput: input];
}

- (void) externalKeyboardDownWithInput: (NSString*) input
{
    float interval = 0.125;

    NSDate* prevDate = [self.repeatExternalKeyDict objectForKey: input];
    
    NSDate *now = [NSDate date];
    [self.repeatExternalKeyDict setObject: now forKey: input];
    
    float diff = [now timeIntervalSinceDate:prevDate];
    if(!prevDate || (diff > interval*2)){
        return [self pushCharacters: input modifiers: 0 autoKeyUp: YES];
    }

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(externalKeyboardUpWithInput:) object:input];
    [self performSelector:@selector(externalKeyboardUpWithInput:) withObject:input afterDelay: interval];
    
    [self pushCharacters: input modifiers: 0 autoKeyUp: NO];
}

- (void) externalKeyboardUpWithInput: (NSString *) inputString
{
    [self pushCharacters: inputString modifiers: 0 autoKeyUp: YES];
    [self.repeatExternalKeyDict removeObjectForKey: inputString];
}

- (void) externalKeyboardGeneric: (UIKeyCommand *) keyCommand
{
    [self externalKeyboardDown: keyCommand];
}

- (void) externalKeyboardKeyCommandPressed: (UIKeyCommand *) keyCommand
{
    [self externalKeyboardCommandDown];
    [self pushCharacters: keyCommand.input modifiers: CommandKeyBit autoKeyUp: YES];
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
