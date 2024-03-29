//
//  SUYCameraViewController.h
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2014/06/04.
//
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>

#import "SUYPhotoViewController.h"

@interface SUYCameraViewController : SUYPhotoViewController

@property (nonatomic, retain)   IBOutlet           UIImageView                  *previewView;

@property (nonatomic, retain)						AVCaptureSession			*session;
@property (nonatomic, retain)						AVCaptureVideoPreviewLayer *previewLayer;

@property (nonatomic, retain)                       AVCaptureDeviceInput        *videoInput;
@property (nonatomic, retain)						AVCaptureStillImageOutput	*stillImageOutput;

@property (retain, nonatomic) IBOutlet UIButton *imagePickerButton;

@property (retain, nonatomic) IBOutlet UIButton *takePictureButton;

- (IBAction)takePicture:  (UIButton *)sender;
- (IBAction)close:(UIButton *)sender;
- (IBAction)toggleCamera:(UIButton *)sender;
- (IBAction)lauchPicker:(id)sender;

@end
