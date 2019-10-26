//
//  SUYPhotoTablePicker.m
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2014/11/15.
//
//

#import "SUYPhotoTablePicker.h"
#import "ELCImagePickerHeader.h"

#import "SUYAssetTablePicker.h"
#import <CoreLocation/CoreLocation.h>
#import <MobileCoreServices/UTCoreTypes.h>

@interface SUYPhotoTablePicker ()
@property (nonatomic, strong) ALAssetsLibrary *specialLibrary;
@property (nonatomic, strong) SUYAssetTablePicker *tablePicker;

@property (nonatomic) BOOL returnsOriginalImage;
@property (nonatomic) BOOL returnsImage;

@property (nonatomic) ELCAsset* prevSelectedAsset;

@end

@implementation SUYPhotoTablePicker

- (void)viewDidLoad {
    [super viewDidLoad];
    _returnsOriginalImage = NO;
    _returnsImage = YES;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.nextButton.enabled = NO;
    [self launchSpecialAlbum];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    self.tablePicker = segue.destinationViewController;
    
}

- (IBAction)launchSpecialAlbum
{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    self.specialLibrary = library;
    NSMutableArray *groups = [NSMutableArray array];
    [_specialLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if (group) {
            [groups addObject:group];
        } else {
            // this is the end
            [self displayPickerForGroup:[groups objectAtIndex:0]];
        }
    } failureBlock:^(NSError *error) {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",nil) message:[NSString stringWithFormat:@"Album Error: %@ - %@", [error localizedDescription], [error localizedRecoverySuggestion]] delegate:nil cancelButtonTitle: NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
        [alert show];
    }];
}

- (void)displayPickerForGroup:(ALAssetsGroup *)group
{
    
    self.tablePicker.parent = self;
    
    self.tablePicker.assetGroup = group;
    [self.tablePicker.assetGroup setAssetsFilter:[ALAssetsFilter allPhotos]];
    
    [self.tablePicker performSelectorInBackground:@selector(preparePhotos) withObject:nil];
}

#pragma mark Actions
- (IBAction)okPushed:(id)sender
{
    [self.tablePicker doneAction:self];
}

#pragma mark ELCImagePickerControllerDelegate Methods

- (void) didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSDictionary *dict = info;
    if ([dict objectForKey:UIImagePickerControllerMediaType] == ALAssetTypePhoto){
        if ([dict objectForKey:UIImagePickerControllerOriginalImage]){
            UIImage* image=[dict objectForKey:UIImagePickerControllerOriginalImage];
            [self.parent openCropper: image];
        } else {
            NSLog(@"UIImagePickerControllerReferenceURL = %@", dict);
        }
    } else {
        NSLog(@"Uknown asset type");
    }
    
}

#pragma mark ELCAssetSelectionDelegate methods

- (BOOL)shouldSelectAsset:(ELCAsset *)asset previousCount:(NSUInteger)previousCount
{
    BOOL shouldSelect = previousCount < 1;
    
    if(self.prevSelectedAsset){
        self.prevSelectedAsset.selected = NO;
        [self.tablePicker reloadData];
        shouldSelect = YES;
    }
    
    if(shouldSelect==YES){
        self.nextButton.enabled = YES;
    }
    
    self.prevSelectedAsset = asset;
    
    return YES;
}

- (BOOL)shouldDeselectAsset:(ELCAsset *)asset previousCount:(NSUInteger)previousCount{
    
    if(previousCount==1){
        self.nextButton.enabled = NO;
    }
    
    return YES;
}

- (void)selectedAssets:(NSArray *)assets{
    
    if(assets.count == 0){return [self.parent close:nil];}
    NSMutableDictionary *workingDictionary = [[NSMutableDictionary alloc] init];
    for(ELCAsset *elcasset in assets) {
        ALAsset *asset = elcasset.asset;
        id obj = [asset valueForProperty:ALAssetPropertyType];
        if (!obj) {
            continue;
        }
        
        CLLocation* wgs84Location = [asset valueForProperty:ALAssetPropertyLocation];
        if (wgs84Location) {
            [workingDictionary setObject:wgs84Location forKey:ALAssetPropertyLocation];
        }
        
        [workingDictionary setObject:obj forKey:UIImagePickerControllerMediaType];
        
        //This method returns nil for assets from a shared photo stream that are not yet available locally. If the asset becomes available in the future, an ALAssetsLibraryChangedNotification notification is posted.
        ALAssetRepresentation *assetRep = [asset defaultRepresentation];
        
        if(assetRep != nil) {
            if (_returnsImage) {
                CGImageRef imgRef = nil;
                //defaultRepresentation returns image as it appears in photo picker, rotated and sized,
                //so use UIImageOrientationUp when creating our image below.
                UIImageOrientation orientation = UIImageOrientationUp;
                
                if (_returnsOriginalImage) {
                    imgRef = [assetRep fullResolutionImage];
                    orientation = [assetRep orientation];
                } else {
                    imgRef = [assetRep fullScreenImage];
                }
                UIImage *img = [UIImage imageWithCGImage:imgRef
                                                   scale:1.0f
                                             orientation:orientation];
                if(img){
                    [workingDictionary setObject:img forKey:UIImagePickerControllerOriginalImage];
                } else {
                    return;
                }
                
            }
            
            [workingDictionary setObject:[[asset valueForProperty:ALAssetPropertyURLs] valueForKey:[[[asset valueForProperty:ALAssetPropertyURLs] allKeys] objectAtIndex:0]] forKey:UIImagePickerControllerReferenceURL];
        }
        
    }
    [self didFinishPickingMediaWithInfo:workingDictionary];
}

@end
