//
//  LauncherViewController.m
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2014/04/10.
//
//

@interface LauncherViewController : UIViewController {
	
	BOOL	squeakVMIsReady;
	BOOL	uiThinksLoginButtonCouldBeEnabled;

}

@property (retain, nonatomic) IBOutlet UIImageView *loadingImage;
@property (retain, nonatomic) IBOutlet UIImageView *cleaningImage;


@property (nonatomic, retain) IBOutlet UIButton *startButton;
@property (nonatomic, retain) IBOutlet UILabel *statusLabel;

- (IBAction) clickStartButton:(id)sender;
- (void) showCleaningImage;

@end
