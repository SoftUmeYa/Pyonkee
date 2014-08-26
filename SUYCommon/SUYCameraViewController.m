//
//  SUYCameraViewController.m
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2014/06/04.
//
//

#import "SUYUtils.h"

#import "UIImage+Resize.h"
#import "SUYCameraViewController.h"
#import "SUYScratchAppDelegate.h"

@interface SUYCameraViewController ()

@end

@implementation SUYCameraViewController


bool isAuthorized = NO;
int shutterCount = 0;

@synthesize previewView, takePictureButton, session, previewLayer, videoInput, stillImageOutput, clientMode;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        
        UIAlertView *myAlertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                              message:@"Device has no camera"
                                                             delegate:nil
                                                    cancelButtonTitle:@"OK"
                                                    otherButtonTitles: nil];
        [myAlertView show];
    }
    
    self.previewView.contentMode = UIViewContentModeCenter;
    
    [self.view addSubview: self.previewView];
    
    [self checkVideoCapturePermission];
    [self setupAVCapture];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [self close: nil];
}

// Re-enable capture session if not currently running
- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self startSession];
    });
}

// Stop running capture session when this view disappears
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
    if(isAuthorized == NO) {return;}
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self stopSession];
    });
}

#pragma mark Session

- (void)startSession {
	if(self.session == nil) {return;}
	if (![self.session isRunning]) {
        //LgInfo(@"startSession ");
		[self.session startRunning];
	}
}

- (void)stopSession {
	if(self.session == nil) {return;}
	if ([self.session isRunning]) {
        //LgInfo(@"stopSession ");
		[self.session stopRunning];
	}
}

#pragma mark Rotation
- (BOOL)shouldAutorotate {
	return YES;
}

- (NSUInteger)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskLandscape;
}


#pragma mark Initialization

- (void)setupAVCapture
{
    LgInfo(@"setupAVCapture");
    
    NSError *error = nil;
    
    self.session = [[AVCaptureSession alloc] init];
    if ([session canSetSessionPreset:AVCaptureSessionPreset640x480]) {
        session.sessionPreset = AVCaptureSessionPreset640x480;
    }
    else {
        LgInfo(@"640x480 not allowed");
    }
    
    AVCaptureDevice *camera = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:camera error:&error];
    if(error){
        LgInfo(@"No video input");
        return;
    }
    [self.session addInput:self.videoInput];
    
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    [self.session addOutput:self.stillImageOutput];
    
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    previewLayer.frame = self.previewView.bounds;
    [[previewLayer connection] setVideoOrientation:[self currentVideoOrientation]];
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    CALayer *viewLayer = self.previewView.layer;
    viewLayer.masksToBounds = YES;
    [viewLayer addSublayer: self.previewLayer];
    
    [self.session startRunning];
}

- (void) checkVideoCapturePermission
{
    NSString *mediaType = AVMediaTypeVideo;
    
    [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
        if (granted)
        {
            //Granted access to mediaType
            isAuthorized = YES;
        }
        else
        {
            //Not granted access to mediaType
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:@"AVCam!"
                                            message:@"AVCam doesn't have permission to use Camera, please change privacy settings"
                                           delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil] show];
                isAuthorized = NO;
            });
        }
    }];
}

#pragma mark - Handle Video Orientation

- (AVCaptureVideoOrientation)currentVideoOrientation {
	UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
	if (deviceOrientation == UIDeviceOrientationLandscapeLeft) {
		return AVCaptureVideoOrientationLandscapeRight;
	} else {
		return AVCaptureVideoOrientationLandscapeLeft;
	}
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	[[self.previewLayer connection] setVideoOrientation:[self currentVideoOrientation]];
}

#pragma mark - Actions


- (IBAction)takePicture:(id)sender
{
    if(isAuthorized == NO){
        LgInfo(@"not authorized");
        [self close: nil];
        return;
    }
    AVCaptureConnection *videoConnection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    
    if (videoConnection == nil) {
        return;
    }
    
    UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
    
    [videoConnection setVideoOrientation: [self currentVideoOrientation]];
    
    
    [self.stillImageOutput
     captureStillImageAsynchronouslyFromConnection:videoConnection
     completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
         if (imageDataSampleBuffer == NULL) {
             return;
         }
         
         NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
         UIImage *image = [[UIImage alloc] initWithData:imageData];
         
         ScratchIPhoneAppDelegate *appDele = (ScratchIPhoneAppDelegate*)[[UIApplication sharedApplication] delegate];
         
         dispatch_async(appDele.defaultSerialQueue, ^(void) {
             [self processTakenPictureImage:image deviceOrientation: deviceOrientation];
         });
         
     }];
}

- (void)processTakenPictureImage:(UIImage *)image deviceOrientation: (UIDeviceOrientation) orient
{
    UIImage *savingImage;
    AVCaptureDevicePosition position = [[self.videoInput device] position];
    if ((orient == AVCaptureVideoOrientationLandscapeRight && position == AVCaptureDevicePositionFront)
            || (orient == AVCaptureVideoOrientationLandscapeLeft && position == AVCaptureDevicePositionBack)) {
        LgInfo(@"**Upside down the image** %d", orient);
        savingImage = [SUYUtils upsideDownImage: image];
    } else {
        savingImage = image;
    }
    
    savingImage = [savingImage resizedImage: [self outImageSize] interpolationQuality:(kCGInterpolationDefault)];
    //LgInfo(@"savingImage %@", savingImage);
    //UIImageWriteToSavedPhotosAlbum(savingImage, self, @selector(savingToPhotosAlbumFinished:didFinishSavingWithError:contextInfo:), nil);
    NSString *filePath = [self saveImage:savingImage];
    [self stopSession];
    ScratchIPhoneAppDelegate *appDele = (ScratchIPhoneAppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDele pickPhoto: filePath];
    [self startSession];
    //[self close: nil];
}

- (IBAction)close:(UIButton*)sender
{
    shutterCount = 0;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)toggleCamera:(id)sender
{
    NSError *error;
	AVCaptureDevicePosition position = [[self.videoInput device] position];
    
	AVCaptureDeviceInput *vidInput;
	if (position == AVCaptureDevicePositionBack) {
		vidInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self cameraPositioned:AVCaptureDevicePositionFront] error:&error];
		self.previewLayer.transform = CATransform3DMakeRotation(M_PI, 0.0f, 1.0f, 0.0f);
	} else {
		vidInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self cameraPositioned:AVCaptureDevicePositionBack] error:&error];
		self.previewLayer.transform = CATransform3DIdentity;
	}
    
	if (vidInput) {
		[self.session beginConfiguration];
		[self.session removeInput:self.videoInput];
		if ([self.session canAddInput:vidInput]) {
			[self.session addInput:vidInput];
			self.videoInput = vidInput;
		}
		[self.session commitConfiguration];
	}
}



- (NSString *)saveImage:(id)image{
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
    shutterCount++;
    NSDate* now = [NSDate date];
    NSInteger intMillSec = (NSInteger) floor([now timeIntervalSinceReferenceDate]);
    NSString* strNow = [NSString stringWithFormat:@"%ld%02d-camImage.png", (long)intMillSec, shutterCount];
    return strNow;
}


- (void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    self.view.superview.bounds = CGRectMake(0, 0, 380, 300);
    self.view.superview.alpha = 0.95;
}

- (AVCaptureDevice *)cameraPositioned:(AVCaptureDevicePosition)position {
	NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
	for (AVCaptureDevice *device in devices) {
		if ([device position] == position) {
			return device;
		}
	}
	return nil;
}

- (void)savingToPhotosAlbumFinished:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo: (void *) contextInfo
{
    if(error){
        LgInfo(@"Photo roll save failed");
        return;
    }
    LgInfo(@"Photo roll saved");
}

- (CGSize)outImageSize{
    if([clientMode isEqualToString: @"stage"]){
        return CGSizeMake(480, 360);
    } else{
        return CGSizeMake(320, 240);
    }
}


@end
