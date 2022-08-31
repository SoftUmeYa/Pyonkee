//
//  SUYDummySensorAccessor.h
//  Scratch
//
//  Created by 梅澤真史 on 2022/08/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SUYDummySensorAccessor : NSObject

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

NS_ASSUME_NONNULL_END
