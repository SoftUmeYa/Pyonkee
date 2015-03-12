//
//  SUYPhotoViewController.h
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2014/12/23.
//
//

#import <UIKit/UIKit.h>

@interface SUYPhotoViewController : UIViewController

@property (nonatomic)                       NSString*        clientMode;

- (NSString *)saveImage:(UIImage*)image;
- (NSString *)targetPathForFileName:(NSString *)name;
- (NSString *)newFileName;
- (CGSize)outImageSize;

@end
