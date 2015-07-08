//
//  SUYCameraViewController.m
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2014/06/04.
//
//


#import "SUYUtils.h"

#import "UIImage+Resize.h"
#import "SUYScratchAppDelegate.h"
#import "SUYCameraViewController.h"

#import "SUYLightSensor.h"

@interface SUYCameraViewController ()

@end

@implementation SUYCameraViewController{
    BOOL isAuthorized;
    NSInteger shutterCount;
    BOOL avoidMirror;
    
    BOOL lightSensorStopped;
}

@synthesize previewView, previewLayer, videoInput, stillImageOutput, clientMode;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    isAuthorized = NO;
    shutterCount = 0;
    avoidMirror = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotate:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        
        UIAlertView *myAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",nil)
                                                              message:NSLocalizedString(@"Device has no camera",nil)
                                                             delegate:nil
                                                    cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                                    otherButtonTitles: nil];
        [myAlertView show];
    }
    
    self.previewView.contentMode = UIViewContentModeCenter;
    [self.view addSubview: self.previewView];
    
    [self checkVideoCapturePermission];
    [self setupAVCapture];

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
        [self.session startRunning];
	}
}

- (void)stopSession {
	if(self.session == nil) {return;}
	if ([self.session isRunning]) {
        [self.session stopRunning];
	}
}

#pragma mark Rotation
-(void) didRotate: (NSNotification *)notification
{
    UIInterfaceOrientation orient = [notification.userInfo[UIApplicationStatusBarOrientationUserInfoKey] integerValue];
    if(UIInterfaceOrientationIsLandscape(orient)){
        [self refreshVideoOrientation];
    }
}

#pragma mark Other Session Management

-(void) restartLightSensorIfNeeded{
    if(lightSensorStopped==YES){
        SUYLightSensor* lightSensor = [SUYLightSensor soleInstance];
        [lightSensor start];
        lightSensorStopped = NO;
    }
}

-(void) stopLightSensorIfRunning{
    SUYLightSensor* lightSensor = [SUYLightSensor soleInstance];
    if(lightSensor.isRunning==YES){
        [lightSensor stop];
        lightSensorStopped = YES;
    }
}

#pragma mark Initialization

- (void)setupAVCapture
{
    NSError *error = nil;
    
    [self stopLightSensorIfRunning];
    
    self.session = [[AVCaptureSession alloc] init];
    if ([_session canSetSessionPreset:AVCaptureSessionPreset640x480]) {
        _session.sessionPreset = AVCaptureSessionPreset640x480;
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
    [_session addInput:self.videoInput];
    
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    [self.session addOutput:self.stillImageOutput];
    
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    previewLayer.frame = self.previewView.bounds;
    previewLayer.connection.videoOrientation =[self currentVideoOrientationByUI];
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    CALayer *viewLayer = self.previewView.layer;
    viewLayer.masksToBounds = YES;
    [viewLayer addSublayer: self.previewLayer];
    
    [_session startRunning];
}

- (void) checkVideoCapturePermission
{
    if ([AVCaptureDevice respondsToSelector:@selector(requestAccessForMediaType: completionHandler:)]==NO){isAuthorized = YES; return;}
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        if (granted)
        {
            isAuthorized = YES;
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [SUYUtils alertWarning:@"No permission to use Camera. Please change privacy settings"];
                isAuthorized = NO;
            });
        }
    }];
}

#pragma mark - Handle Video Orientation

- (AVCaptureVideoOrientation)currentVideoOrientationByUI {
    UIInterfaceOrientation uiOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (uiOrientation == UIInterfaceOrientationLandscapeRight) {
        return AVCaptureVideoOrientationLandscapeRight;
    }
    if (uiOrientation == UIInterfaceOrientationLandscapeLeft){
        return AVCaptureVideoOrientationLandscapeLeft;
    }
    if(uiOrientation == UIInterfaceOrientationPortrait){
        return AVCaptureVideoOrientationPortrait;
    }
    if(uiOrientation == UIInterfaceOrientationPortraitUpsideDown){
        return AVCaptureVideoOrientationPortraitUpsideDown;
    }
    return AVCaptureVideoOrientationLandscapeLeft;
}

- (AVCaptureVideoOrientation)currentVideoOrientationByDevice {
	UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
	if (deviceOrientation == UIDeviceOrientationLandscapeLeft) {
		return AVCaptureVideoOrientationLandscapeRight;
	}
    if (deviceOrientation == UIDeviceOrientationLandscapeRight){
		return AVCaptureVideoOrientationLandscapeLeft;
	}
    if(deviceOrientation == UIDeviceOrientationPortrait){
        return AVCaptureVideoOrientationPortrait;
    }
    if(deviceOrientation == UIDeviceOrientationPortraitUpsideDown){
        return AVCaptureVideoOrientationPortraitUpsideDown;
    }
    //return AVCaptureVideoOrientationLandscapeLeft;
    return [self currentVideoOrientationByUI];
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
    videoConnection.videoOrientation = [self currentVideoOrientationByDevice];
    
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
             [self processTakenPictureImage:image deviceOrientation: videoConnection.videoOrientation];
         });
         
     }];
}

- (void)processTakenPictureImage:(UIImage *)image deviceOrientation: (AVCaptureVideoOrientation) orient
{
    UIImage *savingImage = image;
    CGSize outSize = [self outImageSize];
    AVCaptureDevicePosition position = [[self.videoInput device] position];
    if ((orient == AVCaptureVideoOrientationLandscapeRight && position == AVCaptureDevicePositionFront)
        || (orient == AVCaptureVideoOrientationLandscapeLeft && position == AVCaptureDevicePositionBack))
    {
        LgInfo(@"**Upside down the image** %ld", (long)orient);
        savingImage = [SUYUtils upsideDownImage: image];
    }
    if (UIDeviceOrientationIsPortrait(orient))
    {
        LgInfo(@"**Rotate the image** %ld", (long)orient);
        if(orient == AVCaptureVideoOrientationPortraitUpsideDown){
            savingImage = [SUYUtils rotateLeftImage: image];
        } else {
            savingImage = [SUYUtils rotateRightImage: image];
        }
        outSize = CGSizeMake(outSize.height, outSize.width);
    }
    
    savingImage = [savingImage resizedImage: outSize interpolationQuality:(kCGInterpolationDefault)];
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
    [self restartLightSensorIfNeeded];
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (IBAction)toggleCamera:(id)sender
{
    NSError *error;
	AVCaptureDevicePosition position = [[self.videoInput device] position];
    
	AVCaptureDeviceInput *vidInput;
    UIDeviceOrientation orient = [[UIDevice currentDevice] orientation];
    
    self.previewLayer.transform = CATransform3DIdentity;
    
	if (position == AVCaptureDevicePositionBack) {
		vidInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self cameraPositioned:AVCaptureDevicePositionFront] error:&error];
        if(avoidMirror==YES){[self mirrorToNormalBy:orient];}
    } else {
		vidInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self cameraPositioned:AVCaptureDevicePositionBack] error:&error];
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

- (IBAction)lauchPicker:(id)sender
{
    NSString* origClientMode = self.clientMode;
    [self close: nil];
    ScratchIPhoneAppDelegate *appDele = (ScratchIPhoneAppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDele openPhotoLibraryPicker: origClientMode];
}


#pragma mark - Private

- (NSString *)newFileName
{
    shutterCount++;
    NSDate* now = [NSDate date];
    NSInteger intMillSec = (NSInteger) floor([now timeIntervalSinceReferenceDate]);
    NSString* strNow = [NSString stringWithFormat:@"%ld%02ld-camImage.png", (long)intMillSec, (long)shutterCount];
    return strNow;
}

- (void)mirrorToNormalBy:(UIDeviceOrientation)orient
{
    if(UIDeviceOrientationIsLandscape(orient)){
        self.previewLayer.transform = CATransform3DMakeRotation(M_PI, 0.0f, 1.0f, 0.0f);
    } else {
        self.previewLayer.transform = CATransform3DMakeRotation(M_PI, 1.0f, 0.0f, 0.0f);
    }
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


-(void) refreshVideoOrientation
{
    self.previewLayer.connection.videoOrientation =[self currentVideoOrientationByUI];
}

- (void)savingToPhotosAlbumFinished:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo: (void *) contextInfo
{
    if(error){
        LgInfo(@"Photo roll save failed");
        return;
    }
    LgInfo(@"Photo roll saved");
}

#pragma mark - Layouting
- (void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    self.view.superview.bounds = CGRectMake(0, 0, 380, 300);
    self.view.superview.alpha = 0.95;
}

#pragma mark - Releasing
-(void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [self close: nil];
}

@end
