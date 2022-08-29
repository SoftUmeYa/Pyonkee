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
#import "SUYScratchAppDelegate.h"

#import <SDCAlertView/SDCAlertView.h>

extern ScratchIPhoneAppDelegate *gDelegateApp;
extern struct	VirtualMachine* interpreterProxy;

@interface SUYAlertDialog () {
    NSInteger yesIndex;
    NSInteger noIndex;
    NSInteger okIndex;
    NSInteger semaIndex;
}

@property (nonatomic) SDCAlertController* alertController;

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
    self.alertController = [[SDCAlertController alloc] initWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    semaIndex = si;
    
    if(yesFlag){[self addButtonWithTitle:_yes resultIndex: YES];}
    if(noFlag){[self addButtonWithTitle:_no resultIndex: NO];}
    if(okFlag){[self addButtonWithTitle:_ok resultIndex: YES];}
    if(cancelFlag){[self addCancelButton];}
    
    [self open];
    
    return self;
}

- (instancetype) initForRequestWithTitle: (NSString *) title message: (NSString *) message initialAnswer: (NSString *) initialAnswer cancel: (BOOL) cancelFlag semaIndex: (NSInteger) si {
    self = [super init];
    [self commonInit];
    self.alertController = [[SDCAlertController alloc] initWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    semaIndex = si;
    
    [self.alertController addTextFieldWithHandler:^(UITextField *textField) {
        textField.text = initialAnswer;
    }];
    SDCAlertAction * action = [[SDCAlertAction alloc] initWithTitle:_ok style:UIAlertActionStyleDefault handler:^(SDCAlertAction * ac) {
        UITextField *textField = self.alertController.textFields.firstObject;
        _answerString = textField.text;
        [self clickedButtonAtIndex:YES];
    }];
    [self.alertController addAction:action];
    if(cancelFlag){[self addCancelButton];}
    
    [self open];
    
    return self;
}

#pragma mark - Opening

- (void) open {
    [gDelegateApp.viewController presentViewController:self.alertController animated:YES completion: ^{
    }];
}

#pragma mark - Callback

- (void) addButtonWithTitle: (NSString *) buttonString resultIndex: (NSInteger) index{
    SDCAlertAction * action = [[SDCAlertAction alloc] initWithTitle:buttonString style:SDCAlertActionStyleNormal
                                                    handler:^(SDCAlertAction * ac) {
        [self clickedButtonAtIndex:index];
    }];
    [self.alertController addAction:action];
}

- (void) addCancelButton {
    SDCAlertAction * cancelAction = [[SDCAlertAction alloc] initWithTitle:_cancel style:SDCAlertActionStylePreferred
                                                          handler:^(SDCAlertAction * ac) {
        [self clickedButtonAtIndex:-1];}
    ];
    [self.alertController addAction:cancelAction];
}

- (void)clickedButtonAtIndex:(NSInteger)buttonIndex {
    _buttonPicked = (int)buttonIndex;
    interpreterProxy->signalSemaphoreWithIndex((int)semaIndex);
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (void)abort {
    [self clickedButtonAtIndex: -1];
    [self.alertController dismissViewControllerAnimated:YES completion:nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
}

- (void)alertControllerBackgroundTapped
{
    [self abort];
}

@end
