//
//  SUYPhotoTablePicker.h
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2014/11/15.
//
//

#import <UIKit/UIKit.h>
#import "ELCImagePickerHeader.h"

#import "SUYPhotoPickViewController.h"

@interface SUYPhotoTablePicker : UIViewController<ELCAssetSelectionDelegate>

@property (nonatomic, weak) SUYPhotoPickViewController* parent;
@property (nonatomic) IBOutlet UIButton *nextButton;

@end
