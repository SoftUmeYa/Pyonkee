//
//  SUYPhotoPickViewController.h
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2014/11/15.
//
//

#import <UIKit/UIKit.h>
#import "SUYPhotoViewController.h"

@interface SUYPhotoPickViewController : SUYPhotoViewController


- (IBAction)close:(UIButton*)sender;
- (IBAction)closePushed;

- (void) openCropper:(UIImage*) image;
- (void) saveCroppedImage: (UIImage*)image;


@end
