//
//  SUYSensorAccessor.m
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2015/06/05.
//
//

#import "SUYSensorAccessor.h"
#import "SUYLocationManager.h"
#import "SUYLightSensor.h"

static double MaxSensorVal = 10.0;

static inline double Degrees(double radians){
    return ((radians) * (180.0 / M_PI));
}

static inline BOOL IsInverted(UIInterfaceOrientation orient)
{
    if(UIInterfaceOrientationIsPortrait(orient)){
        return (orient==UIDeviceOrientationPortraitUpsideDown);
    } else {
        return (orient==UIDeviceOrientationLandscapeRight);
    }
}

static inline double DegFromRad(double radians, UIInterfaceOrientation orient)
{
    double degrees = Degrees(radians);
    if(IsInverted(orient)){
        return - (degrees);
    } else {
        return degrees;
    }
    
}

static inline double ValueInRange(double orignal, double min, double max)
{
    return MAX(min,MIN(orignal, max));
}

static inline double Percent(double numerator, double denominator)
{
    return (numerator/denominator)*100.0;
}

@interface SUYSensorAccessor()

@property (nonatomic) CMMotionManager *motionManager;

@end

@implementation SUYSensorAccessor

#pragma mark private
- (double) degFromRad: (double) radians
{
    return DegFromRad(radians, [[UIApplication sharedApplication] statusBarOrientation]);
}

#pragma mark Initialization

- (void)setupMotionManager
{
    if (!_motionManager) {
        _motionManager = [[CMMotionManager alloc] init];
        _motionManager.deviceMotionUpdateInterval = 0.025; //40Hz
    }
}

#pragma mark LocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)authStatus {
    
    if (authStatus==kCLAuthorizationStatusAuthorizedAlways || authStatus == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [self stopLocationManager];
        [self startLocationManager];
    }
}

#pragma mark Actions

- (void) start
{
    [self performSelectorOnMainThread:@selector(startOnMainThread) withObject: nil waitUntilDone: NO];
}

- (void) startOnMainThread
{
    if([self isRunning]){[self stop];}
  
    [self startMotionManager];
    [self startLocationManager];
    [self startLightSensor];
}

-(void) startMotionManager
{
    [self setupMotionManager];
    [self.motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryCorrectedZVertical];
}


-(void) startLocationManager
{
    SUYLocationManager* locMan = [SUYLocationManager soleInstance];
    [locMan start];
}

-(void) startLightSensor
{
    SUYLightSensor* lightSensor = [SUYLightSensor soleInstance];
    [lightSensor start];
}

- (void) stop
{
    [self stopMotionManager];
    [self stopLocationManager];
    [self startLightSensor];
}

-(void) stopMotionManager{
    if (self.motionManager){
        [self.motionManager stopDeviceMotionUpdates];
        self.motionManager = nil;
    }
}

-(void) stopLocationManager{
    SUYLocationManager* locMan = [SUYLocationManager soleInstance];
    [locMan stop];
}

-(void) stopLightSensor
{
    SUYLightSensor* lightSensor = [SUYLightSensor soleInstance];
    [lightSensor stop];
}

#pragma mark Testing
- (BOOL) isRunning
{
    if(self.motionManager==nil){return NO;}
    return self.motionManager.isDeviceMotionActive;
}

- (BOOL) isPortrait
{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    return UIInterfaceOrientationIsPortrait(orientation);
}

- (BOOL) isInverted
{
    return IsInverted([[UIApplication sharedApplication] statusBarOrientation]);
}

#pragma mark Mode Accessing
-(int) runningMode
{
    return (int)[self isRunning];
}

#pragma mark Sensor Value Accessing

-(CMDeviceMotion*) deviceMotion{
    return self.motionManager.deviceMotion;
}

-(double) accX
{
    if([self isPortrait]){return self.deviceMotion.gravity.x;}
    return self.deviceMotion.gravity.y;
}
-(double) accY
{
    if([self isPortrait]){return self.deviceMotion.gravity.y;}
    return self.deviceMotion.gravity.x;
}
-(double) accZ
{
    return self.deviceMotion.gravity.z;
}

-(double) gyroX
{
    if([self isPortrait]){return -[self degFromRad: self.deviceMotion.rotationRate.x];} //on portrait, we invert x direction
    return [self degFromRad: self.deviceMotion.rotationRate.y];
}
-(double) gyroY
{
    double rawVal = [self isPortrait]? self.deviceMotion.rotationRate.y : self.deviceMotion.rotationRate.x;
    return [self degFromRad: rawVal];
}
-(double) gyroZ
{
    return Degrees(self.deviceMotion.rotationRate.z) * -1;
}

-(double) pitch
{
    if([self isPortrait]){return -[self degFromRad: self.deviceMotion.attitude.pitch];} //on portrait, we invert pitch direction
    return [self degFromRad: self.deviceMotion.attitude.roll];
}
-(double) roll
{
    if([self isPortrait]){return [self degFromRad:self.deviceMotion.attitude.roll];}
    return [self degFromRad: self.deviceMotion.attitude.pitch];
}
-(double) yaw
{
    return Degrees(self.deviceMotion.attitude.yaw) * -1;
}

-(double) northHeading
{
    return [SUYLocationManager soleInstance].northHeading;
}

-(double) brightness
{
    SUYLightSensor* lightSensor = [SUYLightSensor soleInstance];
    double rawBrightness = lightSensor.brightness;
    return ValueInRange(rawBrightness, 0.0, MaxSensorVal)*10; //0-100
}



@end
