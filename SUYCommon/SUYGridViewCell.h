//
//  SUYGridViewCell.h
//  ScratchOnIPad
//
//  Created by Masashi Umezawa on 2020/02/09.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SUYGridViewCell : UICollectionViewCell

@property (nonatomic, strong) UIImage *thumbnailImage;

-(void) showSelectionMark;
-(void) hideSelectionMark;

@end

NS_ASSUME_NONNULL_END
