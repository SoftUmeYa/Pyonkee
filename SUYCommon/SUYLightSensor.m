//
//  SUYLightSensor.m
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2015/06/05
//
//

#import "SUYLightSensor.h"

#import "SUYUtils.h"
#import <ImageIO/ImageIO.h>

@interface SUYLightSensor()

@property (nonatomic) AVCaptureSession*   session;
@property (nonatomic) double   brightness;

@property (nonatomic, retain)   AVCaptureDeviceInput        *videoInput;
@property (nonatomic, retain)   AVCaptureVideoDataOutput	*videoImageOutput;

@end


@implementation SUYLightSensor {
    BOOL isAuthorized;
}


#pragma mark Actions
- (void) start
{
    
    if([self isRunning]){
        [self stop];
    }
    
    if(isAuthorized==NO){
        [self checkVideoCapturePermission];
    }
    
    NSError *error = nil;
    
    self.session = [[AVCaptureSession alloc] init];
    if ([self.session canSetSessionPreset:AVCaptureSessionPreset352x288]) {
        self.session.sessionPreset = AVCaptureSessionPreset352x288;
    }
    else {
        LgInfo(@"352x288 not allowed");
    }
    
    AVCaptureDevice *camera = [self selectCaptureDevice];
    
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:camera error:&error];
    if(error){
        LgInfo(@"No video input");
        return;
    }
    [self.session addInput:self.videoInput];
    [self setSlowFpsTo:camera];
    
    dispatch_queue_t queue = dispatch_queue_create("lightSensorQueue", NULL);
    self.videoImageOutput = [[AVCaptureVideoDataOutput alloc] init];
    [self.videoImageOutput setSampleBufferDelegate:self queue:queue];
    [self.session addOutput:self.videoImageOutput];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.session startRunning];
    });
}

- (void) stop
{
    [self stopSession];
    self.session = nil;
}

-(BOOL) isRunning
{
    if(self.session == nil){return NO;}
    
    return self.session.isRunning;
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

#pragma mark Private

- (AVCaptureDevice *)selectCaptureDevice
{
    AVCaptureDeviceDiscoverySession *captureDeviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera]
                                          mediaType:AVMediaTypeVideo
                                           position:AVCaptureDevicePositionFront];
    NSArray *videoDevices = [captureDeviceDiscoverySession devices];
    AVCaptureDevice *captureDevice = nil;
    for (AVCaptureDevice *device in videoDevices)
    {
        if (device.position == AVCaptureDevicePositionFront)
        {
            captureDevice = device;
            break;
        }
    }
    
    if ( ! captureDevice)
    {
        captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    
    return captureDevice;
}

-(void) setSlowFpsTo: (AVCaptureDevice*) device
{
    int fps                             = 5;  // Change this value
    [device lockForConfiguration:nil];
    [device setActiveVideoMinFrameDuration:CMTimeMake(1, fps)];
    [device setActiveVideoMaxFrameDuration:CMTimeMake(1, fps)];
    [device unlockForConfiguration];
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
                [SUYUtils alertWarning:@"No permission to use Camera. For getting brightness value, please change privacy settings"];
                isAuthorized = NO;
            });
        }
    }];
}

#pragma mark Delegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CFDictionaryRef metadataDict = CMCopyDictionaryOfAttachments(NULL, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
    NSDictionary *metadata = [[NSMutableDictionary alloc] initWithDictionary:(__bridge NSDictionary*)metadataDict];
    CFRelease(metadataDict);
    
    NSDictionary *exifMetadata = [[metadata objectForKey:(NSString *)kCGImagePropertyExifDictionary] mutableCopy];
    self.brightness = [[exifMetadata objectForKey:(NSString *)kCGImagePropertyExifBrightnessValue] doubleValue];
    
    //LgInfo(@"<%f>", self.brightness);
}

#pragma mark Instance creation

+ (SUYLightSensor*) soleInstance
{
    static SUYLightSensor* soleInstance = nil;
    if (!soleInstance) {
        soleInstance = [[super allocWithZone:nil] init];
    }
    return soleInstance;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [self soleInstance];
}


@end
