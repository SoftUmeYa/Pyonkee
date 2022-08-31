//
//  SUYDummySensorAccessor.m
//  Scratch
//
//  Created by 梅澤真史 on 2022/08/25.
//

#import "SUYDummySensorAccessor.h"

@implementation SUYDummySensorAccessor


#pragma mark Actions

- (void) start{}
- (void) stop{}

#pragma mark Testing
- (BOOL) isRunning{
    return NO;
}

#pragma mark Accessing
-(int) runningMode{
    return 0;
}


-(double) accX
{
    return 0.0;
}
-(double) accY
{
    return 0.0;
}
-(double) accZ
{
    return 0.0;
}

-(double) gyroX
{
    return 0.0;
}
-(double) gyroY
{
    return 0.0;
}
-(double) gyroZ
{
    return 0.0;
}

-(double) pitch
{
    return 0.0;
}
-(double) roll
{
    return 0.0;
}
-(double) yaw
{
    return 0.0;
}

-(double) northHeading
{
    return 0.0;
}

-(double) brightness
{
    return 0.0;
}

@end
