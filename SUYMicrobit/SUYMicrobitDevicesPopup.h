//
//  SUYMicrobitDevicesPopup.h
//  Scratch
//
//  Created by Masashi Umezawa on 2021/04/12.
//

#import <Foundation/Foundation.h>

#import "SUYMicrobitAccessor.h"


NS_ASSUME_NONNULL_BEGIN

@interface SUYMicrobitDevicesPopup : NSObject

+ (instancetype) openOn:(SUYMicrobitAccessor *)accessor;
+ (void) closeCurrent;
- (void) open;
- (void) close;

@end

NS_ASSUME_NONNULL_END
