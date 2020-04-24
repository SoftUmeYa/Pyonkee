//
//  SUYTablePhotoPicker.h
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2020/1/30.
//
//

#import <UIKit/UIKit.h>
#import "SUYPhotoCollecitonViewController.h"
#import "SUYPhotoPickViewController.h"

@interface SUYTablePhotoPicker : UIViewController<SUYPhotoCollecitonViewControllerDelegate>

@property (nonatomic, weak) SUYPhotoPickViewController* parent;
@property (nonatomic) IBOutlet UIButton *nextButton;

@end
