//
//  SUYSensorAccessor.h
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2015/06/05.
//
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import <CoreLocation/CoreLocation.h>

@interface SUYSensorAccessor : NSObject <CLLocationManagerDelegate>

@property (nonatomic) UIInterfaceOrientation currentInterfaceOrientation;

@property (nonatomic,readonly)   double   accX;
@property (nonatomic,readonly)   double   accY;
@property (nonatomic,readonly)   double   accZ;

@property (nonatomic,readonly)   double   gyroX;
@property (nonatomic,readonly)   double   gyroY;
@property (nonatomic,readonly)   double   gyroZ;

@property (nonatomic,readonly)   double   yaw;
@property (nonatomic,readonly)   double   pitch;
@property (nonatomic,readonly)   double   roll;

@property (nonatomic, readonly)   double   northHeading;

@property (nonatomic,readonly)   double   brightness;

#pragma mark Actions

- (void) start;
- (void) stop;

#pragma mark Testing
- (BOOL) isRunning;

#pragma mark Accessing
-(int) runningMode;

@end
