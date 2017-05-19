//
//  SUYiCloudAccessor.m
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2017/04/14.
//
//

#import "SUYiCloudAccessor.h"

#import "SUYUtils.h"

@implementation SUYiCloudAccessor{
    
}

static SUYiCloudAccessor *soleInstance;


#pragma mark - Initialization

- (void) initialize {
    self.currentContainerToken = nil;
}

#pragma mark - Actions

- (void) detectiCloud {
    
    [self detectContainerToken];
    if([self containerTokenIsAvailable] == NO){
        return;
    }
    [self listenNotifications];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.iCloudContainerURL = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier: nil];
        LgInfo(@"#### iCloud is available: %@", self.iCloudContainerURL);
        if (self.iCloudContainerURL != nil){
            [self touchContainer];
        }
    });
}

- (BOOL) containerTokenIsAvailable{
    return self.currentContainerToken != nil;
}

- (void) listenNotifications{
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector (iCloudAccountAvailabilityChanged:) name: NSUbiquityIdentityDidChangeNotification object: nil];
}

#pragma mark - Accessing

- (NSData*) storedTokenValue{
    return [[NSUserDefaults standardUserDefaults] dataForKey:kTokenKey];
}

- (NSString*) iCloudContainerDirectory{
    if(self.iCloudContainerURL){
        return self.iCloudContainerURL.path;
    }
    return nil;
}

- (NSString*) iCloudContainerBaseDirectory{
    return [[self iCloudContainerDirectory] stringByDeletingLastPathComponent];
}

#pragma mark - Callback

- (void) iCloudAccountAvailabilityChanged: (NSNotification*) aNotification{
    [self detectContainerToken];
}

#pragma mark - Testing
- (BOOL) belongsToiCloudContainerBaseDirectory: (NSString*) filePath{
    NSString *contBaseDir = [[SUYiCloudAccessor soleInstance] iCloudContainerBaseDirectory];
    return [filePath hasPrefix:contBaseDir];
}

#pragma mark - Private

- (void) detectContainerToken{
    self.currentContainerToken = [NSFileManager defaultManager].ubiquityIdentityToken;
    
    if(self.currentContainerToken)
    {
        NSData *newTokenData=[NSKeyedArchiver archivedDataWithRootObject: self.currentContainerToken];
        [[NSUserDefaults standardUserDefaults] setObject: newTokenData forKey: kTokenKey];
        
    }
    else
    {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey: kTokenKey];
    }
}

- (void) touchContainer {
    NSURL *url = [self.iCloudContainerURL URLByAppendingPathComponent:@"_last_launch_.txt"];
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    NSError *error = nil;
    [coordinator coordinateWritingItemAtURL:url options:0 error:&error byAccessor:^(NSURL *newURL) {
        NSError *touchError = nil;
        NSDate *now = [NSDate date];
        double unixtime = [now timeIntervalSince1970];
        [[NSString stringWithFormat:@"%f", unixtime] writeToURL:newURL atomically:YES encoding:NSUTF8StringEncoding error:&touchError];
        //[[NSFileManager defaultManager] removeItemAtURL:newURL error:nil];
    }];
}

#pragma mark - Actions
- (void) openUrl: (NSURL*) externalFileUrl succeeded: (void (^)(NSString *pathStr))blk {
    
    LgInfo(@"###openImporting: %@ %@",externalFileUrl, externalFileUrl.path);
    
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    NSError *error = nil;
    __block NSString *newPath;
    
    [coordinator coordinateReadingItemAtURL:externalFileUrl options:0 error:&error byAccessor:^(NSURL *newURL) {
        NSData *data = [NSData dataWithContentsOfURL:newURL];
        newPath = [[SUYUtils documentDirectory] stringByAppendingPathComponent: newURL.lastPathComponent];
        newPath = [newPath precomposedStringWithCanonicalMapping];
        BOOL result = [data writeToFile: newPath atomically:YES];
        if(result){
            LgInfo(@"###openImporting: opening resource: %@", newPath);
            blk(newPath);
        }
    }];
    if (error) {
        LgError(@"###openImporting FAILED: %@",error);
    }
}

#pragma mark - Instance creation

+ (instancetype)soleInstance;
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        soleInstance = [(SUYiCloudAccessor *)[super allocWithZone:NULL] init];
    });
    return soleInstance;
}

- (id)init
{
    if (self == soleInstance) return soleInstance;
    
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [self soleInstance];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}


@end
