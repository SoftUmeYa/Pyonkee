//
//  SUYMenuDialog.h
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2014/04/30.

#import <Foundation/Foundation.h>


@interface SUYMenuDialog : NSObject {
	NSInteger semaIndex;
    NSInteger buttonNumber;
}

@property (nonatomic,strong) UIAlertController *alertController;


@property (nonatomic,retain) NSMutableDictionary *buttonIndexs;
@property int resultIndex;

- (SUYMenuDialog *) initTitle: (NSString *) title message: (NSString *) message semaIndex: (NSInteger) si;

//- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex;

- (void) addButtonWithTitle: (NSString *) buttonString;
- (void) addCancelButton;

- (void) showInView: (UIView*) originator;
@end
