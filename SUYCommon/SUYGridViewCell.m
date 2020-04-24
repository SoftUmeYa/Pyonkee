//
//  SUYGridViewCell.m
//  ScratchOnIPad
//
//  Created by Masashi Umezawa on 2020/02/09.
//

#import "SUYGridViewCell.h"

@interface SUYGridViewCell ()
@property (strong) IBOutlet UIImageView *imageView;
@end

@implementation SUYGridViewCell

static NSString *const kDefaultCheckmarkFile = @"tick-flat";

#pragma mark Actions

- (void)setThumbnailImage:(UIImage *)thumbnailImage {
    _thumbnailImage = thumbnailImage;
    self.imageView.image = thumbnailImage;
    self.imageView.highlightedImage = [self checkmarkedImageFrom:thumbnailImage];
}

-(void) showSelectionMark {
    self.imageView.highlighted = YES;
}

-(void) hideSelectionMark {
    self.imageView.highlighted = NO;
}

#pragma mark Private

-(UIImage *)checkmarkedImageFrom:(UIImage*)bgImage
{
    UIImage *fgImage = [UIImage imageNamed:kDefaultCheckmarkFile];
    CGSize bgImageSize = bgImage.size;
    CGSize boundsSize = self.bounds.size;
    
    UIGraphicsBeginImageContext(bgImageSize);
    [bgImage drawInRect:CGRectMake( 0, 0, bgImageSize.width, bgImageSize.height)];
    [bgImage drawInRect:CGRectMake( 0, 0, bgImageSize.width, bgImageSize.height) blendMode:kCGBlendModeDifference alpha:0.2f];
    [fgImage drawInRect:CGRectMake( (bgImageSize.width - boundsSize.width)/2, (bgImageSize.height - boundsSize.height)/2, boundsSize.width, boundsSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return newImage;
}

@end
