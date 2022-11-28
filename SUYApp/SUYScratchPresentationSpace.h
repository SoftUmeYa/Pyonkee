//
//  SUYScratchPresentationSpace.h
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2014/06/20
//  Modified, customized version of ScratchIPhonePresentationSpace.h
//
//  Originally Created by John M McIntosh on 10-02-15.
//  Copyright 2010 Corporate Smalltalk Consulting Ltd. All rights reserved.
//
//

#import "SqueakUIController.h"
#import "ScratchRepeatKeyMetaData.h"
#import "ScratchPresentationUITextField.h"
#import "GSRadioButtonSetController.h"

@interface ScratchIPhonePresentationSpace : UIViewController <UIScrollViewDelegate, UITextFieldDelegate, UIPopoverPresentationControllerDelegate, UIDocumentPickerDelegate, GSRadioButtonSetControllerDelegate> {

  	NSInteger	characterCounter;
	NSMutableDictionary *repeatKeyDict;
	
}
@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;
@property (nonatomic, retain) IBOutlet SqueakUIController *scrollViewController;
@property (nonatomic, retain) IBOutlet UIButton *fontScaleButton;
@property (nonatomic, retain) IBOutlet UIButton *shoutGoLandscapeButton;
@property (nonatomic, retain) IBOutlet UIButton *stopAllLandscapeButton;
@property (nonatomic, retain) IBOutlet UIButton *padLockButton;
@property (nonatomic, retain) IBOutlet UIButton *commandButton;
@property (nonatomic, retain) IBOutlet UIButton *shiftButton;

@property (nonatomic, retain) IBOutlet UITextField *softKeyboardField;
@property (nonatomic, retain) IBOutlet UIButton *softKeyboardOnButton;
@property (nonatomic, retain) IBOutlet UIButton *presentationExitButton;

@property (nonatomic, retain) IBOutlet ScratchPresentationUITextField *textField;

@property (nonatomic, retain) IBOutlet GSRadioButtonSetController *radioButtonSetController;

@property (nonatomic, retain) NSMutableDictionary *repeatKeyDict;
@property (nonatomic, retain) UIView *landscapeToolBar;
@property (nonatomic, retain) UIView *landscapeToolBar2;
@property (nonatomic, retain) UIView *viewModeBar;
@property (nonatomic, retain) UIActivityIndicatorView *indicatorView;

@property (nonatomic, readonly) UIInterfaceOrientation formerOrientation;

@property(nonatomic, readonly) NSArray *keyCommands;

@property (retain, nonatomic) IBOutlet NSLayoutConstraint *scrollViewHeightConstraint;
@property (retain, nonatomic) IBOutlet NSLayoutConstraint *modeBarLeadingConstraint;
@property (retain, nonatomic) IBOutlet NSLayoutConstraint *modeBarWidthConstraint;


- (IBAction) shoutGo:(id)sender;
- (IBAction) stopAll:(id)sender;
- (IBAction) exitPresentation:(id)sender;

- (IBAction) openFontResizer:(id)sender;
- (IBAction) openCamera: (NSString*)stageOrNot;
- (IBAction) openPhotoLibraryPicker:(NSString*)stageOrNot;
- (IBAction) openHelp:(NSString *)url;

- (IBAction) textMorphFocused: (BOOL)status;
- (IBAction) showWaitIndicator;
- (IBAction) hideWaitIndicator;
- (IBAction) keyUpArrow:(id)sender;
- (IBAction) keyDownArrow:(id)sender;
- (IBAction) keyLeftArrow:(id)sender;
- (IBAction) keyRightArrow:(id)sender;
- (IBAction) keyTouchUp:(id)sender;
- (IBAction) keySpace: (id) sender;
- (IBAction) operatePadLock: (id) sender;

- (IBAction) keyboardActivate: (id) sender;
- (IBAction) keyboardDeactivate: (id) sender;

- (IBAction) commandButtonUp: (id) sender;
- (IBAction) commandButtonDown: (id) sender;
- (IBAction) shiftButtonUp: (id) sender;
- (IBAction) shiftButtonDown: (id) sender;

- (void) postOpen;
- (void) pushCharacter: (NSString*) string;
- (void) startRepeatKeyProcess: (unichar) character for: (id) sender;
- (void) startRepeatKeyAction: (NSString*) string  for: (id) sender;
- (int)  viewModeIndex;

- (void) airDropProject: (NSString *)projectPath;
- (void) exportToCloud: (NSString *)resourcePath;
- (void) importFromCloud;

- (void) openMeshDialog;

- (BOOL) isViewModeBarHidden;
- (BOOL) isInPresentationMode;
- (BOOL) isPresentationButtonOn;

- (void) fixLayoutOnWindowResizing;
- (void) fixSizeOfSubViewsIfNeeded;

@end
