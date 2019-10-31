//
//  SUYLocationManager.m
//
//  Created by Masashi UMEZAWA on 2015/06/12.

#import "SUYLocationManager.h"

@interface SUYLocationManager()

@property (nonatomic) CLLocationManager *locationManager;

@end

@implementation SUYLocationManager

#pragma mark - Accessing

- (CLLocationManager*) locationManager
{
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
    }
    return _locationManager;
}

- (double) northHeading
{
    return self.locationManager.heading.magneticHeading;
}

#pragma mark - Delegate

//- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager
//{
//    return YES;
//}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    LgInfo(@"LOC %@", locations);
    CLAuthorizationStatus authStatus = CLLocationManager.authorizationStatus;
    if(authStatus == kCLAuthorizationStatusAuthorizedAlways || authStatus == kCLAuthorizationStatusAuthorizedWhenInUse){
        if(CLLocationManager.headingAvailable == YES){
            self.locationManager.delegate = self;
            [self start];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    LgInfo(@"ERR %@", error);
    [self stop];
}



#pragma mark - Actions

- (void) start
{
    [self.locationManager startUpdatingHeading];
}
- (void) stop
{
    [self.locationManager stopUpdatingHeading];
}

#pragma mark - Initialization

- (void) setup
{
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    _locationManager.headingFilter = kCLHeadingFilterNone;
    
    CLAuthorizationStatus authStatus = CLLocationManager.authorizationStatus;
    if(authStatus == kCLAuthorizationStatusNotDetermined){
        if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            [self.locationManager requestWhenInUseAuthorization];
            //[self.locationManager requestAlwaysAuthorization];
        }
    }
    if(authStatus == kCLAuthorizationStatusAuthorizedAlways || authStatus == kCLAuthorizationStatusAuthorizedWhenInUse){
        if(CLLocationManager.headingAvailable == YES){
            self.locationManager.delegate = self;
            [self start];
        }
    }
    if(authStatus == kCLAuthorizationStatusRestricted || authStatus == kCLAuthorizationStatusDenied){
        LgInfo(@"authStatus ERR %ul", authStatus);
    }
    
}

- (id) init
{
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

#pragma mark Instance creation

+ (SUYLocationManager*) soleInstance
{
    static SUYLocationManager* soleInstance = nil;
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
