//
//  SUYMenuDialog.m
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2014/04/30.
//

#import "SUYMenuDialog.h"
#import "sq.h"

extern struct	VirtualMachine* interpreterProxy;


@implementation SUYMenuDialog
@synthesize actionsView,buttonIndexs,resultIndex;

- (SUYMenuDialog *) initTitle: (NSString *) title message: (NSString *) message semaIndex: (NSInteger) si {
    self = [super init];
    self.actionsView = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(title, nil) delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    semaIndex = si;
    resultIndex = -1;
	self.buttonIndexs = [NSMutableDictionary dictionaryWithCapacity: 10];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(abort) name:@"squeakVmWillReset" object:nil];
	return self;
}

- (void) showInView: (UIView *) originator
{
    [self.actionsView addButtonWithTitle: @""];
    [self.actionsView setCancelButtonIndex: actionsView.numberOfButtons - 1];
	[self.actionsView showInView: originator];
}

- (void) addButtonWithTitle: (NSString *) buttonString {
	NSInteger buttonNumber = [self.actionsView addButtonWithTitle: buttonString];
	[self.buttonIndexs setObject: buttonString forKey: [NSNumber numberWithInteger: buttonNumber]];
}

- (void) addCancelButton {
	[self addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
}

- (void)actionSheet:(UIActionSheet *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	resultIndex = buttonIndex;
	interpreterProxy->signalSemaphoreWithIndex(semaIndex);
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}


- (void)abort {
    [self.actionsView dismissWithClickedButtonIndex:self.actionsView.cancelButtonIndex animated:NO];
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
}

@end
