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


@interface SUYAlertDialog () {
    NSInteger yesIndex;
    NSInteger noIndex;
    NSInteger okIndex;
    NSInteger semaIndex;
}

@property (nonatomic) UIAlertView* alertView;

@property (nonatomic) NSString* yes;
@property (nonatomic) NSString* no;
@property (nonatomic) NSString* cancel;
@property (nonatomic) NSString* ok;

@end

@implementation SUYAlertDialog

#pragma mark - Initialization

- (void) commonInit{
    _yes = NSLocalizedString(@"Yes",nil);
    _no = NSLocalizedString(@"No",nil);
    _cancel = NSLocalizedString(@"Cancel",nil);
    _ok = NSLocalizedString(@"OK",nil);
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(abort) name:@"squeakVmWillReset" object:nil];
}

- (instancetype) initTitle: (NSString *) title message: (NSString *) message yes: (BOOL) yesFlag no: (BOOL) noFlag 
						  okay: (BOOL) okFlag cancel: (BOOL) cancelFlag semaIndex: (NSInteger) si {
    self = [super init];
    [self commonInit];
	self.alertView = [[UIAlertView alloc] initWithTitle: title message: message delegate: self cancelButtonTitle: (cancelFlag ? _cancel : nil) otherButtonTitles: nil];
	yesIndex = yesFlag ? [self.alertView addButtonWithTitle: _yes] : -1;
	noIndex = noFlag ? [self.alertView addButtonWithTitle: _no] : -1;
	okIndex = okFlag ? [self.alertView addButtonWithTitle: _ok] : -1;
	semaIndex = si;
    [self.alertView show];
	return self;
}

- (instancetype) initForRequestWithTitle: (NSString *) title message: (NSString *) message initialAnswer: (NSString *) initialAnswer cancel: (BOOL) cancelFlag semaIndex: (NSInteger) si {
    NSString *cancel = NSLocalizedString(@"Cancel",nil);
    self = [super init];
    [self commonInit];
    self.alertView = [[UIAlertView alloc] initWithTitle: title message: message delegate: self cancelButtonTitle: (cancelFlag ? cancel : nil) otherButtonTitles: nil];
    self.alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    yesIndex = noIndex = -1;
    self.alertView.cancelButtonIndex = 1;
    UITextField *textField = [self.alertView textFieldAtIndex:0];
    [textField setText:initialAnswer];
    textField.delegate = self;
    okIndex = [self.alertView addButtonWithTitle: _ok];
    semaIndex = si;
    [self.alertView show];
    return self;
}

#pragma mark - Callback

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    UITextField *textField;
    if(self.alertView.alertViewStyle == UIAlertViewStylePlainTextInput){
        textField = [self.alertView textFieldAtIndex:0];
    }
    
    if(textField){
        textField.delegate = nil;
    }
    self.alertView = nil;
    
	if (alertView.cancelButtonIndex == buttonIndex) {
		_buttonPicked = -1;
	}
	if (yesIndex == buttonIndex) {
		_buttonPicked = 1;
	}
	if (noIndex == buttonIndex) {
		_buttonPicked = 0;
	}
	if (okIndex == buttonIndex) {
		_buttonPicked = 1;
        _answerString = [textField text];
	}
	interpreterProxy->signalSemaphoreWithIndex((int)semaIndex);
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (void)abort {
    [self.alertView dismissWithClickedButtonIndex:self.alertView.cancelButtonIndex animated:NO];
    [[NSNotificationCenter defaultCenter] removeObserver: self];

}

- (BOOL)textFieldShouldReturn:(UITextField *)alertTextField {
    if(self.alertView){
        [alertTextField resignFirstResponder];
    }
    return YES;
}

@end
