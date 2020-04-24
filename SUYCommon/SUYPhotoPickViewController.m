//
//  SUYPhotoPickViewController.m
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2014/11/15.
//
//

#import "SUYPhotoPickViewController.h"

#import "SUYTablePhotoPicker.h"

#import "SUYPhotoCropper.h"

#import "SUYUtils.h"
#import "UIImage+Resize.h"

#import "SUYScratchAppDelegate.h"

@interface SUYPhotoPickViewController ()

@property (nonatomic) UINavigationController* embedNavigationController;

@end

@implementation SUYPhotoPickViewController

#pragma mark - View Callbacks

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated   {
    [super viewDidAppear:animated];
    [self openTablePicker];
}

- (void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    self.view.superview.bounds = CGRectMake(0, 0, 960, 720);
    self.view.superview.alpha = 1.0;
}


#pragma mark - Actions

- (IBAction)close:(UIButton*)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)closePushed
{
    [self.embedNavigationController popViewControllerAnimated:NO];
}

- (IBAction)openTablePicker
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"SUYTablePhotoPicker" bundle:[NSBundle mainBundle]];
    SUYTablePhotoPicker *tablePicker = (SUYTablePhotoPicker*)[storyboard instantiateInitialViewController];
    
    tablePicker.parent = self;
    
    [self.embedNavigationController pushViewController:tablePicker animated:NO];
}

- (void) openCropper:(UIImage*) image {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"SUYPhotoCropper" bundle:[NSBundle mainBundle]];
    SUYPhotoCropper *cropper = (SUYPhotoCropper*)[storyboard instantiateInitialViewController];
    
    cropper.parent = self;
    [cropper initWithSourceImage: image];
    
    [self.embedNavigationController pushViewController:cropper animated:NO];
}


#pragma mark - Saving
- (void) saveCroppedImage: (UIImage*)croppedImage
{
    UIImage* savingImage = [croppedImage resizedImage: [self outImageSize] interpolationQuality:(kCGInterpolationDefault)];
    NSString* filePath = [self saveImage:savingImage];
    
    if(filePath){
        ScratchIPhoneAppDelegate *appDele = (ScratchIPhoneAppDelegate*)[[UIApplication sharedApplication] delegate];
        [appDele pickPhoto: filePath];
    }
    [self close: nil];
}

#pragma mark - Saving Image Overrides

- (NSString *)newFileName
{
    NSDate* now = [NSDate date];
    NSInteger intMillSec = (NSInteger) floor([now timeIntervalSinceReferenceDate]);
    NSString* strNow = [NSString stringWithFormat:@"%ld%02d-cropImage.png", (long)intMillSec, 1];
    return strNow;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    self.embedNavigationController = (UINavigationController*)segue.destinationViewController;
    self.embedNavigationController.navigationBarHidden = YES;
    
}

#pragma mark - Releasing

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




@end
