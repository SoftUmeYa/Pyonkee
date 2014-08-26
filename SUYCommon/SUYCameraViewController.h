//
//  SUYCameraViewController.h
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2014/06/04.
//
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface SUYCameraViewController : UIViewController

@property (nonatomic, retain)   IBOutlet           UIImageView                  *previewView;
@property (nonatomic, retain)   IBOutlet           UIButton                *takePictureButton;

@property (nonatomic, retain)						AVCaptureSession			*session;
@property (nonatomic, retain)						AVCaptureVideoPreviewLayer *previewLayer;

@property (nonatomic, retain)                       AVCaptureDeviceInput        *videoInput;
@property (nonatomic, retain)						AVCaptureStillImageOutput	*stillImageOutput;

@property (nonatomic, retain)                       NSString*        clientMode;

- (IBAction)takePicture:  (UIButton *)sender;
- (IBAction)close:(UIButton *)sender;
- (IBAction)toggleCamera:(UIButton *)sender;

@end
