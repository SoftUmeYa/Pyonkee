//
//  SUYPhotoViewController.m
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2014/12/23.
//
//

#import "SUYPhotoViewController.h"
#import "SUYUtils.h"

@interface SUYPhotoViewController ()

@end

@implementation SUYPhotoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

#pragma mark - Actions
- (NSString *)saveImage:(UIImage*)image{
    //NSData *bmpData = UIImageJPEGRepresentation(image, 0.85);
    NSData *bmpData = UIImagePNGRepresentation(image);
    NSString *filePath = [self targetPathForFileName:[self newFileName]]; //Add the file name
    [bmpData writeToFile:filePath atomically:YES];
    //LgInfo(@"saveImage %@", filePath);
    return filePath;
}

#pragma mark - Private

- (NSString *)targetPathForFileName:(NSString *)name
{
    //NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES); //NSCachesDirectory
    //NSString *documentsPath = [paths objectAtIndex:0];
    NSString *path = [SUYUtils tempDirectory];
    return [path stringByAppendingPathComponent:name];
}

- (NSString *)newFileName
{
    NSDate* now = [NSDate date];
    NSInteger intMillSec = (NSInteger) floor([now timeIntervalSinceReferenceDate]);
    NSString* strNow = [NSString stringWithFormat:@"%ld%02d-camImage.png", (long)intMillSec, 1];
    return strNow;
}

- (CGSize)outImageSize{
    if([self.clientMode isEqualToString: @"stage"]){
        return CGSizeMake(480, 360);
    } else{
        return CGSizeMake(320, 240);
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
