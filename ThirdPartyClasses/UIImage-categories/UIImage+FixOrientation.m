//
//  UIImage+FixOrientation.m
//  GKImagePicker
//
//  Created by Genki Kondo on 5/27/13.
//  Copyright (c) 2013 Genki Kondo. All rights reserved.
//

#import "UIImage+FixOrientation.h"

@implementation UIImage (FixOrientation)
- (UIImage *)fixOrientation {
    if (self.imageOrientation == UIImageOrientationUp) return self;
    
    UIGraphicsBeginImageContextWithOptions(self.size, NO, self.scale);
    [self drawInRect:(CGRect){0, 0, self.size}];
    UIImage *normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return normalizedImage;
}
@end
