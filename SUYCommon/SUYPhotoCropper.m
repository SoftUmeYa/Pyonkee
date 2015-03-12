//
//  SUYPhotoCropper.m
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2014/11/16.
//
//

#import "SUYPhotoCropper.h"

#import "HFImageEditorViewController.h"
#import "HFImageEditorViewController+Private.h"

@interface SUYPhotoCropper ()

@end

@implementation SUYPhotoCropper


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated
{
    
    [super viewDidAppear:animated];
    
    CGSize imageSize = [self.parent outImageSize];
    
    self.cropRect = CGRectMake((roundf(self.frameView.frame.size.width-imageSize.width)/2),
                               (roundf(self.frameView.frame.size.height-imageSize.height)/2),
                               roundf(imageSize.width),
                               roundf(imageSize.height));
    
    [self reset:NO];
}


#pragma mark - Initialization

-(void) awakeFromNib
{
    
    //self.minimumScale = 0.2;
    self.maximumScale = 20;
    __weak __typeof__(self) weakSelf = self;
    self.doneCallback = ^(UIImage *editedImage, BOOL canceled){
        if(!canceled) {
            [weakSelf applyCroppedImage: editedImage];
        } else {
            [weakSelf.parent closePushed];
        }
    };
    
    self.rotateEnabled = YES;
    //self.checkBounds = YES;
    
}


- (void) initWithSourceImage: (UIImage*) sourceImage{
    self.sourceImage = sourceImage;
}


#pragma mark - Actions

- (void) applyCroppedImage: (UIImage*) editedImage
{
    [self.parent saveCroppedImage: editedImage];
}


#pragma mark - Updating

- (void) updatePreview
{
    //[self.imageEditorViewController setImage:self.currentImage];
    //[self setLandscapeAction: self];
}

#pragma mark - Releasing

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
