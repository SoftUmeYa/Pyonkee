//
//  SUYLocationManager.h
//
//  Created by Masashi UMEZAWA on 2015/06/12.

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import <CoreLocation/CoreLocation.h>

@interface SUYLocationManager : NSObject<CLLocationManagerDelegate>

@property (nonatomic, readonly) CLLocationManager* locationManager;

@property (nonatomic, readonly) double northHeading;


- (void) start;
- (void) stop;

+ (SUYLocationManager*) soleInstance;

@end
