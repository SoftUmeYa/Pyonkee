//
//  SUYScratchSceneDelegate.h
//  ScratchOnIPad
//
//  Created for SceneDelegate migration
//

#import <UIKit/UIKit.h>
#import "SqueakUIView.h"
#import "SqueakUIController.h"
#import "sqSqueakAppDelegate.h"
#import "sqiPhoneScreenAndWindow.h"

@class ScratchIPhonePresentationSpace;
@class SUYNavigationController;

@interface SUYScratchSceneDelegate : UIResponder <UIWindowSceneDelegate>

@property (nonatomic,strong) UIWindow *window;
@property (nonatomic,strong) SUYNavigationController *viewController;

@property (nonatomic,strong) SqueakUIView *mainView;
@property (nonatomic,strong) UIScrollView *scrollView;
@property (nonatomic,strong) sqiPhoneScreenAndWindow *screenAndWindow;

@property (nonatomic,strong) ScratchIPhonePresentationSpace* presentationSpace;

- (void) setupSqueakMainView;
- (void) startPlaying;

- (void) restart;

@end
