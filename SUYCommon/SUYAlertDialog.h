//
//  CSCAlertDialog.h
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2014/07/26
//  Modified, customized version of CSCAlertDialog.h
//
//  Originally Created by John M McIntosh on 10-01-31.
//  Copyright 2010 Corporate Smalltalk Consulting Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SUYAlertDialog : NSObject <UIAlertViewDelegate> {
	NSInteger yesIndex;
	NSInteger noIndex;
	NSInteger okIndex;
	NSInteger buttonPicked;
	NSInteger semaIndex;
}

@property (nonatomic,assign) NSInteger buttonPicked;
@property (nonatomic,retain) UIAlertView* alertView;

- (SUYAlertDialog *) initTitle: (NSString *) title message: (NSString *) message yes: (BOOL) yesFlag no: (BOOL) noFlag 
						  okay: (BOOL) okFlag cancel: (BOOL) cancelFlag semaIndex: (NSInteger) semaIndex;
@end
