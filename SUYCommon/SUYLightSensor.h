//
//  SUYLightSensor.h
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2015/06/05
//
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface SUYLightSensor : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, readonly) double   brightness;

- (void) start;
- (void) stop;
- (BOOL) isRunning;

+ (SUYLightSensor*) soleInstance;

@end
