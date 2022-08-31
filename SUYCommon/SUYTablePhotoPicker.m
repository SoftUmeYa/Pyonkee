//
//  SUYPhotoTablePicker.m
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2020/1/30.
//
//

#import "SUYTablePhotoPicker.h"
#import "SUYPhotoCollecitonViewController.h"

#import "SUYUtils.h"

@interface SUYTablePhotoPicker ()
@property (nonatomic) SUYPhotoCollecitonViewController *photoCollectionViewController;

@property (nonatomic) PHAsset *pickedAsset;

@end

@implementation SUYTablePhotoPicker

- (void)viewDidLoad {
    [super viewDidLoad];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.nextButton.enabled = (self.pickedAsset != NULL);
    [self setupPhotoCollectionViewController];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    self.photoCollectionViewController = segue.destinationViewController;
}

#pragma mark Initialize
- (void)setupPhotoCollectionViewController {
    self.photoCollectionViewController.delegate = self;
}

#pragma mark Actions
- (IBAction)okPushed:(id)sender
{
    [self openCropperWithImage];
}

#pragma mark Private

- (void) openCropperWithImage
{
    [self fetchImageFromAsset:self.pickedAsset resultHandler:^(UIImage *image, NSDictionary *info) {
        BOOL isDegraded = [info[PHImageResultIsDegradedKey] boolValue];
        if (isDegraded == YES) {return;}
        dispatch_async(dispatch_get_main_queue(), ^{
            [SUYUtils hideActivityToastOn: self.view];
            if(image){
                [self.parent openCropper: image];
            } else {
                [SUYUtils alertInfo: (NSLocalizedString(@"Cannot download",nil))];
            }
        });
    }];
}

- (void) fetchImageFromAsset:(PHAsset *)asset resultHandler:(void (^)(UIImage *_Nullable result, NSDictionary *_Nullable info))resultHandler;
{
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.synchronous = NO;
    options.networkAccessAllowed = YES;
    options.resizeMode = PHImageRequestOptionsResizeModeExact;
    UIView* toastBackView = self.view;
    [SUYUtils showActivityToastOn: toastBackView];
    options.progressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
        if(progress == 1.0 || !error){
            dispatch_async(dispatch_get_main_queue(), ^{
                [SUYUtils hideActivityToastOn: toastBackView];
            });
        }
    };
    CGSize targetSize = CGSizeMake(asset.pixelWidth, asset.pixelHeight);
    [[PHCachingImageManager defaultManager] requestImageForAsset:asset targetSize:targetSize contentMode:PHImageContentModeDefault options:options resultHandler:resultHandler];
}

#pragma mark - SUYPhotoCollecitonViewControllerDelegate

- (void)photoCollecitonViewController:(SUYPhotoCollecitonViewController *)photoCollecitonViewController didSelectPhoto:(PHAsset *)photo {
    self.pickedAsset = photo;
    self.nextButton.enabled = YES;
}
- (void)photoCollecitonViewController:(SUYPhotoCollecitonViewController *)photoCollecitonViewController didDeselectPhoto:(PHAsset *)photo {
    self.pickedAsset = NULL;
    self.nextButton.enabled = NO;
}

@end
