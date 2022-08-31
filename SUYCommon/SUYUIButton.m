//
//  SUYUIButton.m
//  ScratchOnIPad
//
//  Created by Masashi Umezawa on 2022/08/03.
//

#import "SUYUIButton.h"

@interface SUYUIButton ()
@end

@implementation SUYUIButton

#pragma mark Override

-(BOOL) pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    int offset = 12;
    CGRect newArea = CGRectMake(self.bounds.origin.x - offset, self.bounds.origin.y - offset, self.bounds.size.width + (offset*2), self.bounds.size.height + (offset*2));
    return CGRectContainsPoint(newArea, point);
}

@end
