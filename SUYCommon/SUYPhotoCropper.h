//
//  SUYPhotoCropper.h
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2014/11/16.
//
//

#import <UIKit/UIKit.h>

#import "SUYPhotoPickViewController.h"

#import "HFImageEditorViewController.h"

@interface SUYPhotoCropper : HFImageEditorViewController


@property (nonatomic, weak) SUYPhotoPickViewController* parent;


- (void) initWithSourceImage: (UIImage*) sourceImage;

@end
