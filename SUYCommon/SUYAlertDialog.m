//
//  SUYAlertDialog.m
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2014/07/26
//  Modified, customized version of CSCAlertDialog.m
//
//  Originally Created by John M McIntosh on 10-01-31.
//  Copyright 2010 Corporate Smalltalk Consulting Ltd. All rights reserved.
//

#import "SUYAlertDialog.h"
#import "sq.h"

extern struct	VirtualMachine* interpreterProxy;


@implementation SUYAlertDialog
@synthesize buttonPicked;

- (SUYAlertDialog *) initTitle: (NSString *) title message: (NSString *) message yes: (BOOL) yesFlag no: (BOOL) noFlag 
						  okay: (BOOL) okFlag cancel: (BOOL) cancelFlag semaIndex: (NSInteger) si {
	NSString *yes = NSLocalizedString(@"Yes",nil);
	NSString *no = NSLocalizedString(@"No",nil);
	NSString *cancel = NSLocalizedString(@"Cancel",nil);
	NSString *ok = NSLocalizedString(@"OK",nil);
    self = [super init];
	self.alertView = [[UIAlertView alloc] initWithTitle: title message: message delegate: self cancelButtonTitle: (cancelFlag ? cancel : nil) otherButtonTitles: nil];
	yesIndex = yesFlag ? [self.alertView addButtonWithTitle: yes] : -1;
	noIndex = noFlag ? [self.alertView addButtonWithTitle: no] : -1;
	okIndex = okFlag ? [self.alertView addButtonWithTitle: ok] : -1;
	semaIndex = si;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(abort) name:@"squeakVmWillReset" object:nil];
	[self.alertView show];
	return self;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (alertView.cancelButtonIndex == buttonIndex) {
		self.buttonPicked = -1;
	}
	if (yesIndex == buttonIndex) {
		self.buttonPicked = 1;
	}
	if (noIndex == buttonIndex) {
		self.buttonPicked = 0;
	}
	if (okIndex == buttonIndex) {
		self.buttonPicked = 1;
	}
	
	interpreterProxy->signalSemaphoreWithIndex(semaIndex);
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (void)abort {
    [self.alertView dismissWithClickedButtonIndex:self.alertView.cancelButtonIndex animated:NO];
    [[NSNotificationCenter defaultCenter] removeObserver: self];

}


@end
