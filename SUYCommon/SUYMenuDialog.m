//
//  SUYMenuDialog.m
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2014/04/30.
//

#import "SUYMenuDialog.h"
#import "sq.h"
#import "SUYUtils.h"
#import "SUYScratchAppDelegate.h"

extern ScratchIPhoneAppDelegate *gDelegateApp;

extern struct	VirtualMachine* interpreterProxy;


@implementation SUYMenuDialog
@synthesize alertController,buttonIndexs,resultIndex;

- (SUYMenuDialog *) initTitle: (NSString *) title message: (NSString *) message semaIndex: (NSInteger) si {
    self = [super init];
    self.alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(title, nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
                            
    semaIndex = si;
    resultIndex = -1;
    buttonNumber = 0;
	self.buttonIndexs = [NSMutableDictionary dictionaryWithCapacity: 10];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(abort) name:@"squeakVmWillReset" object:nil];
	return self;
}

- (void) showInView: (UIView *) originator
{
    //[self addCancelButton];
    
    self.alertController.modalPresentationStyle = UIAlertControllerStyleActionSheet;
    self.alertController.popoverPresentationController.sourceView = originator;
    self.alertController.popoverPresentationController.sourceRect = originator.frame;
    [gDelegateApp.viewController presentViewController:self.alertController animated:YES completion: ^{
        [self restoreDisplayIfNeeded];
        UIView* backView = self.alertController.view.superview.subviews[1];
        backView.userInteractionEnabled = YES;
        [backView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget: self action: @selector(alertControllerBackgroundTapped)]];
    }];

}

- (void)alertControllerBackgroundTapped
{
    [self abort];
}

- (void) addButtonWithTitle: (NSString *) buttonString {
    NSInteger idx = buttonNumber++;
    UIAlertAction * action = [UIAlertAction actionWithTitle:buttonString style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * ac) {
                                                              [self clickedButtonAtIndex:idx];
                                                          }];
    [self.alertController addAction:action];
    
}

- (void) addCancelButton {
    
    UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * ac) {[self abort];}];
    [self.alertController addAction:cancelAction];
    
}

- (void)clickedButtonAtIndex:(NSInteger)buttonIndex {
    resultIndex = (int)buttonIndex;
    interpreterProxy->signalSemaphoreWithIndex((int)semaIndex);
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [self restoreDisplayIfNeeded];
}

- (void)abort {
    [self clickedButtonAtIndex: buttonNumber + 1];
    [self.alertController dismissViewControllerAnimated:YES completion:nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
}

- (void) restoreDisplayIfNeeded {
    [gDelegateApp restoreDisplayIfNeeded];
}

@end
