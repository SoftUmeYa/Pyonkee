//
//  SUYAssetTablePicker.h
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2015/02/28.
//
//  Simplified ELCAssetTablePicker for supporting easier single selection

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "ELCAsset.h"
#import "ELCAssetSelectionDelegate.h"
#import "ELCAssetPickerFilterDelegate.h"

@interface SUYAssetTablePicker : UITableViewController <ELCAssetDelegate>

@property (nonatomic, weak) id <ELCAssetSelectionDelegate> parent;
@property (nonatomic, strong) ALAssetsGroup *assetGroup;
@property (nonatomic, strong) NSMutableArray *elcAssets;

- (int)totalSelectedAssets;
- (void)preparePhotos;
- (void)doneAction:(id)sender;
- (void)reloadData;

@end