//
//  SUYPhotoCollecitonViewController.h
//  ScratchOnIPad
//
//  Created by Masashi Umezawa on 2020/02/08.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@class SUYPhotoCollecitonViewController;

@protocol SUYPhotoCollecitonViewControllerDelegate <NSObject>

@optional
- (void)photoCollecitonViewController:(SUYPhotoCollecitonViewController *)photoCollecitonViewController didSelectPhoto:(PHAsset *)photo;
- (void)photoCollecitonViewController:(SUYPhotoCollecitonViewController *)photoCollecitonViewController didDeselectPhoto:(PHAsset *)photo;
@end

@interface SUYPhotoCollecitonViewController : UICollectionViewController

@property (strong) PHFetchResult *assetsFetchResults;
@property (strong) PHAssetCollection *assetCollection;
@property (nonatomic, weak) id<SUYPhotoCollecitonViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
