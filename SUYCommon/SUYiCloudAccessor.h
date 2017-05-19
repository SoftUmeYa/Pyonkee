//
//  SUYiCloudAccessor.h
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2017/04/14.
//
//

#import <Foundation/Foundation.h>

static NSString *const kTokenKey = @"com.softumeya.Pyonkee.UbiquityIdentityToken";

@interface SUYiCloudAccessor : NSObject

@property (nonatomic, strong) NSURL* iCloudContainerURL;
@property (nonatomic, strong) id currentContainerToken;


+ (SUYiCloudAccessor*) soleInstance;

- (void) detectiCloud;
- (BOOL) containerTokenIsAvailable;
- (NSString*) iCloudContainerDirectory;
- (NSString*) iCloudContainerBaseDirectory;
- (BOOL) belongsToiCloudContainerBaseDirectory: (NSString*) filePath;

- (void) openUrl: (NSURL*) externalFileUrl succeeded: (void (^)(NSString *pathStr))blk;

@end
