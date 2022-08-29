//
//  SUYUtils.m
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2014/04/10.
//
//

#ifdef SUY_DEBUG
#import <mach/mach.h>
#endif

#import "SqueakUIViewCALayer.h"
//#import "SqueakUIViewOpenGL.h"

#import "UIImage+Resize.h"

#import "SUYAudioFileConverter.h"
#import "Pyonkee-Swift.h"

#import "SUYUtils.h"

#import <SDCAlertView/SDCAlertView.h>

@implementation SUYUtils

#pragma mark Testing

+ (BOOL) isIPadIdiom
{
    return [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
}
+ (BOOL) isRetina
{
    LgInfo(@"isRetina: %f", [[UIScreen mainScreen] scale]);
    return ([UIScreen instancesRespondToSelector:@selector(scale)] && [[UIScreen mainScreen] scale] == 2.0);
}
+ (BOOL) isOnMac
{
    BOOL isiOSAppOnMac = OVER_IOS14 && [[NSProcessInfo processInfo] isiOSAppOnMac];
    BOOL isMacCatalyst = TARGET_OS_MACCATALYST;
    return (isiOSAppOnMac || isMacCatalyst);
}
+ (BOOL) canSendMail
{
    return [MFMailComposeViewController canSendMail];
}

#pragma mark Actions


+ (void) showWait {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

+ (void) hideWait {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

+ (void) showCursor: (int) cursorCode {
    LgInfo(@"showCursor %i", cursorCode);
    [SUYTouchCursor showEyeDropper];
}

+ (void) hideCursor {
    [SUYTouchCursor hide];
}

+ (BOOL) cursorEnabled {
    return [SUYTouchCursor IsEnabled];
}

+ (UIImage *)upsideDownImage:(UIImage*)origImage{
    return [UIImage imageWithCGImage:origImage.CGImage scale:1.0 orientation:UIImageOrientationDown];
}

+ (UIImage *)rotateRightImage:(UIImage*)origImage{
    return [UIImage imageWithCGImage:origImage.CGImage scale:1.0 orientation:UIImageOrientationRight];
}

+ (UIImage *)rotateLeftImage:(UIImage*)origImage{
    return [UIImage imageWithCGImage:origImage.CGImage scale:1.0 orientation:UIImageOrientationLeft];
}

+ (UIImage *)offsetImage:(UIImage*)origImage transposed: (CGRect) rect offset: (CGPoint) offset size: (CGSize) size {
    
    CGAffineTransform transform = CGAffineTransformMakeTranslation(offset.x , offset.y);
    CGFloat scale = 1.0f;
    CGRect transposedRect = rect;
    CGImageRef imageRef = origImage.CGImage;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmap = CGBitmapContextCreate(
                                                NULL,
                                                size.width,
                                                size.height,
                                                8, /* bits per channel */
                                                (size.width * 4), /* 4 channels per pixel * numPixels/row */
                                                colorSpace,
                                                kCGImageAlphaPremultipliedLast
                                                );
    CGColorSpaceRelease(colorSpace);
    CGContextConcatCTM(bitmap, transform);
    CGContextSetInterpolationQuality(bitmap, kCGInterpolationDefault);
    CGContextDrawImage(bitmap, transposedRect, imageRef);
    CGImageRef newImageRef = CGBitmapContextCreateImage(bitmap);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef scale:scale orientation:UIImageOrientationUp];
    CGContextRelease(bitmap);
    CGImageRelease(newImageRef);
    
    return newImage;
    
}

+(NSString*)saveAiffFromPath: (NSString*) fromPath;
{
    SUYAudioFileConverter* converter = [[SUYAudioFileConverter alloc] init];
    return [converter saveAiffFromPath:fromPath];
}

#pragma mark Files

+(void) trimResourcePathOnLaunch: (NSString*) resourcePath max: (int) max
{
    NSFileManager* fm = [NSFileManager defaultManager];
    
    NSString* parentDirName = [resourcePath stringByDeletingLastPathComponent];
    
    NSArray *allFileNames = [fm contentsOfDirectoryAtPath:parentDirName error:nil];
    
    NSMutableArray* allPathNames = [NSMutableArray arrayWithCapacity: allFileNames.count];
    
    for (NSString *fName in allFileNames) {
        NSString* path = [parentDirName stringByAppendingPathComponent:fName];
        [allPathNames addObject:path];
    }
    NSArray*  pathNamesSorted = [allPathNames sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSDictionary* first_properties  = [fm attributesOfItemAtPath:obj1 error:nil];
        NSDate*       first             = [first_properties  fileModificationDate];
        NSDictionary* second_properties = [fm attributesOfItemAtPath:obj1 error:nil];
        NSDate*       second            = [second_properties fileModificationDate];
        return [second compare:first];
    }];

    if(pathNamesSorted.count > max){
        for(int i = 0; i < pathNamesSorted.count; i++){
            NSString* path = pathNamesSorted[i];
            if([resourcePath compare:path] != NSOrderedSame){
       //         LgInfo(@"#del# # INBOX path %@ ", path);
                [fm removeItemAtPath: path error:nil];
                break;
            }
        }
    }
    
}

+ (void)removeFilesMatches:(NSString*)regexString inPath:(NSString*)path {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString options:NSRegularExpressionCaseInsensitive error:nil];
    NSFileManager* fm = [NSFileManager defaultManager];
    NSDirectoryEnumerator *filesEnumerator = [fm enumeratorAtPath:path];
    NSString *file;
    NSError *error;
    while (file = [filesEnumerator nextObject]) {
        NSUInteger match = [regex numberOfMatchesInString:file options:0 range:NSMakeRange(0, [file length])];
        if (match) {
            [fm removeItemAtPath:[path stringByAppendingPathComponent:file] error:&error];
        }
    }
}

#pragma mark - Testing

+ (BOOL) belongsToTempDirectory: (NSString*) filePath {
    NSString *tempBaseDir = [self tempDirectory];
    return [filePath hasPrefix:tempBaseDir];
}

+ (int) fileExists: (NSString*)fileName inDirectory: (NSString*)path{
    NSString* pathName = [path stringByAppendingPathComponent:fileName];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:pathName]){
        return 1;
    };
    return 0;
}

#pragma mark Accessing

+ (CGSize) rootViewSizeOf: (UIView *)view {
    while (view.superview != nil) {
        view = view.superview;
    }
    return view.bounds.size;
}

+ (UIInterfaceOrientation) interfaceOrientation {
    if([self isOnMac]){
        return UIInterfaceOrientationLandscapeLeft;
    }
    if(OVER_IOS13){
        return [UIApplication sharedApplication].windows.firstObject.windowScene.interfaceOrientation;
    }
    return [[UIApplication sharedApplication] statusBarOrientation];
}

#pragma mark Defaults

+ (Class) squeakUIViewClass{
    //Currently, we do not use OpenGL
    //return [SqueakUIViewOpenGL class];
    return [SqueakUIViewCALayer class];
}

+ (CGSize) scratchScreenSize
{
    return CGSizeMake(1024,768);
}

+ (float) scratchScreenZoomScale
{
    CGFloat expandRatio = [self landscapeScreenHeight] / [self scratchScreenSize].height;
    return 1.0f * expandRatio;
}

+ (CGFloat) landscapeScreenHeight
{
    CGRect screenRect = [UIScreen mainScreen].bounds;
    CGSize screenSize = screenRect.size;
    CGFloat screenHeight = screenSize.height;
    
    if (OVER_IOS11) {
        UIWindow *window = UIApplication.sharedApplication.keyWindow;
        CGFloat bottomPadding = window.safeAreaInsets.bottom;
        screenHeight = screenHeight - bottomPadding;
        if (TARGET_OS_MACCATALYST){
            CGFloat windowHeight = window.bounds.size.height - bottomPadding;
            return MAX(windowHeight, screenHeight);
        }
    }
    return MIN(screenSize.width, screenHeight);
}

+ (NSString *)applicationSupportDirectory {
    NSString *applicationSupportDirectory = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
    NSError *error = nil;
    if ( ![[NSFileManager defaultManager] fileExistsAtPath:applicationSupportDirectory isDirectory:NULL] ) {
        if (![[NSFileManager defaultManager]
              createDirectoryAtPath:applicationSupportDirectory
              withIntermediateDirectories:NO
              attributes:nil
              error:&error])
        {
            NSAssert(NO, ([NSString stringWithFormat:@"Failed to create App Support directory %@ : %@", applicationSupportDirectory,error]));
            NSLog(@"Error creating application support directory at %@ : %@",applicationSupportDirectory,error);
            return nil;
        }
        else
        {
            NSURL *dirPath = [NSURL fileURLWithPath:applicationSupportDirectory isDirectory:YES];
            int result = [self addSkipBackupAttributeToItemAtURL:dirPath];
            if(!result) {
                NSLog(@"Error addSkipBackupAttributeToItemAtURL");
                return nil;
            }
        }
    }
    return applicationSupportDirectory;
}

+ (NSString *)tempDirectory {
    NSString *path = NSTemporaryDirectory();
    return path;
}

+ (NSString *)documentDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(
                                                         NSDocumentDirectory,
                                                         NSUserDomainMask,
                                                         YES);
    return [paths objectAtIndex:0];
}

+ (NSString *)documentInboxDirectory
{
    NSString *path = [[self documentDirectory] stringByAppendingPathComponent:@"Inbox"];
    return path;
}

+ (NSString *)bundleResourceDirectoryWith: (NSString*)subDir {
    NSString *path = [[NSBundle mainBundle] resourcePath];
    return [path stringByAppendingPathComponent: subDir];
}

+ (NSString *)currentCountry{
    
    if((OVER_IOS9)){
        NSString* lang = [[NSLocale preferredLanguages] objectAtIndex:0];
        NSArray *names = [lang componentsSeparatedByString:@"-"];
        NSString* possibleRegion = names[1];
        if(names.count>=1 && possibleRegion.length==2){
            return possibleRegion;
        }
    }
    
    NSString* ccode = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
    if(ccode==nil){
        return @"";
    }
    return ccode;
}

+ (NSString *)currentLanguage{
    NSString* lang = [[NSLocale preferredLanguages] objectAtIndex:0];
    
    NSArray *names = [lang componentsSeparatedByString:@"-"];
    if(names.count>=1 && (OVER_IOS9)){
        lang = names[0];
        for(int i=1; i < names.count-1; i++){
            NSString* part = names[i];
            lang = [lang stringByAppendingFormat:@"-%@", part];
        }
        if([lang isEqualToString:@"zh"]){
            NSString* region = names[names.count-1];
            if([region isEqualToString:@"TW"] || [region isEqualToString:@"HK"]){
                lang = [lang stringByAppendingFormat:@"-%@", @"Hant"];
            }
        }
        
    }
    
    LgInfo(@"CURRENT-LANG %@", lang);
    return lang;
}

+ (NSArray*) supportedUtis{
    return @[@"com.softumeya.scratch-project",@"com.softumeya.scratch-sprite",
             @"com.microsoft.waveform-audio",@"public.mp3",
             @"com.compuserve.gif",@"com.microsoft.bmp",@"public.png",@"public.jpeg",@"public.utf8-plain-text"];
}


#pragma mark Private

+ (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL
{
    assert([[NSFileManager defaultManager] fileExistsAtPath: [URL path]]);
    
    NSError *error = nil;
    BOOL success = [URL setResourceValue: [NSNumber numberWithBool: YES]
                                  forKey: NSURLIsExcludedFromBackupKey error: &error];
    if(!success){
        NSLog(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
    }
    return success;
}

#pragma mark Toast

+ (void) showToast: (NSString*) message image: (UIImage*) image title: (NSString*) title {
    [SUYToast showToastWithMessage:message image:image title: title duration: 1];
}

+ (void) showToastOn:(UIView*) view message:(NSString*) message image: (UIImage*) image title: (NSString*) title {
    [SUYToast showToastOnView:view message:message image:image title: title duration: 1];
}

+ (void) showActivityToastOn:(UIView*) view{
    [SUYToast showActivityToastOnView:view];
}

+ (void) hideActivityToastOn:(UIView*) view{
    [SUYToast hideActivityToastOnView:view];
}

#pragma mark Alert

+ (void) inform:(NSString*)message duration:(int)msecs {
    dispatch_async (
        dispatch_get_main_queue(),
        ^{
            SDCAlertController *alert = [[SDCAlertController alloc]
                                    initWithTitle:message message: @"" preferredStyle:SDCAlertControllerStyleAlert];
            [alert presentAnimated:NO completion:nil];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, msecs* NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
                [alert dismissViewControllerAnimated:NO completion:nil];
            });
         }
    );
}

+ (void) alertWarning: (NSString*) msg
{
    SDCAlertController *alert = [self newAlert:NSLocalizedString(msg,nil) title: NSLocalizedString(@"Warning",nil)];
    [alert addAction:[[SDCAlertAction alloc] initWithTitle:NSLocalizedString(@"OK",nil) style:SDCAlertActionStylePreferred handler:nil]];
    [alert presentAnimated:NO completion:nil];
}

+ (void) alertInfo:(NSString*)message {
    SDCAlertController *alert = [self newInfoAlert:message title:@""];
    [alert presentAnimated:NO completion:nil];
}

+ (SDCAlertController*) newAlert:(NSString*)message title: (NSString*)title{
    SDCAlertController *alertController = [[SDCAlertController alloc] initWithTitle:title message:message preferredStyle:SDCAlertControllerStyleAlert];
    return alertController;
}

+ (SDCAlertController*) newInfoAlert:(NSString*)message title: (NSString*)title {
    SDCAlertController *alert = [self newAlert:message title: title];
    [alert addAction:[[SDCAlertAction alloc] initWithTitle:NSLocalizedString(@"OK",nil) style:SDCAlertActionStylePreferred handler:nil]];
    return alert;
}

#pragma mark Stats

+(void) printMemStats{
#ifdef SUY_DEBUG
   LgInfo(@"@@##!!STATS!!!##@@ app %lu", [self getAppMemory]);
#endif
}

#ifdef SUY_DEBUG
+ (vm_size_t)getFreeMemory {
    
    mach_port_t host_port;
    mach_msg_type_number_t host_size;
    vm_size_t pagesize;
    
    host_port = mach_host_self();
    host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    host_page_size(host_port, &pagesize);
    vm_statistics_data_t vm_stat;
    
    if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS) {
        LgError(@"Failed to fetch vm statistics");
        return 0;
    }
    
    vm_size_t mem_free = vm_stat.free_count * pagesize;
    
    return (unsigned int)mem_free;
}


+(vm_size_t) getAppMemory {
    struct task_basic_info basic_info;
    mach_msg_type_number_t t_info_count = TASK_BASIC_INFO_COUNT;
    kern_return_t status;

    status = task_info(current_task(), TASK_BASIC_INFO,
                   (task_info_t)&basic_info, &t_info_count);

    if (status != KERN_SUCCESS)
    {
        LgError(@"%s(): Error in task_info(): %s",
          __FUNCTION__, strerror(errno));
    }

    vm_size_t residentSize = basic_info.resident_size;
    return residentSize;
}
#endif

@end
