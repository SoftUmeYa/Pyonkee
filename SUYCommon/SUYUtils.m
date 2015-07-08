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
#import "SqueakUIViewOpenGL.h"

#import "SUYUtils.h"

@implementation SUYUtils

#pragma mark Testing

+ (BOOL) isIPad
{
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
}
+ (BOOL) isRetina
{
    LgInfo(@"isRetina: %f", [[UIScreen mainScreen] scale]);
    return ([UIScreen instancesRespondToSelector:@selector(scale)] && [[UIScreen mainScreen] scale] == 2.0);
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


+ (UIImage *)upsideDownImage:(UIImage*)origImage{
    return [UIImage imageWithCGImage:origImage.CGImage scale:1.0 orientation:UIImageOrientationDown];
}

+ (UIImage *)rotateRightImage:(UIImage*)origImage{
    return [UIImage imageWithCGImage:origImage.CGImage scale:1.0 orientation:UIImageOrientationRight];
}

+ (UIImage *)rotateLeftImage:(UIImage*)origImage{
    return [UIImage imageWithCGImage:origImage.CGImage scale:1.0 orientation:UIImageOrientationLeft];
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

#pragma mark Defaults

+ (Class) squeakUIViewClass{
    //Currently, we do not use OpenGL
    //if([SUYUtils isRetina]){
    if(YES){
        return [SqueakUIViewCALayer class];
    }
    return [SqueakUIViewOpenGL class];
}

+ (CGSize) scratchScreenSize
{
    return CGSizeMake(1024,768);
}

+ (float) scratchScreenZoomScale;
{
    //    if([SUYUtils isRetina]){
    //        return 1.25f * 2.0;
    //    }
    
    return 1.0f;
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

+ (NSString *)bundleResourceDirectoryWith: (NSString*)subDir {
    NSString *path = [[NSBundle mainBundle] resourcePath];
    return [path stringByAppendingPathComponent: subDir];
}

+ (NSString *)currentCountry{
    NSString* ccode = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
    if(ccode==nil){
        return @"";
    }
    return ccode;
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


#pragma mark Alert

+ (void) inform:(NSString*)message duration:(int)msecs for:(id)dele {
    dispatch_async (
        dispatch_get_main_queue(),
        ^{
            UIAlertView *alert = [[UIAlertView alloc]
                                    initWithTitle:@"" message: message delegate: dele cancelButtonTitle:nil otherButtonTitles:nil];
            [alert show];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, msecs* NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
               [alert dismissWithClickedButtonIndex:0 animated:NO];
            });
         }
    );
}

+ (void) alertWarning: (NSString*) msg
{
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning",nil)
                                message:NSLocalizedString(msg,nil)
                               delegate:nil
                      cancelButtonTitle:NSLocalizedString(@"OK",nil)
                      otherButtonTitles:nil] show];
}

#pragma mark Stats

+(void) printMemStats{
#ifdef SUY_DEBUG
   LgInfo(@"@@##!!STATS!!!##@@ app %u", [self getAppMemory]);
#endif
}

#ifdef SUY_DEBUG
+ (unsigned int)getFreeMemory {
    
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
    
    natural_t mem_free = vm_stat.free_count * pagesize;
    
    return (unsigned int)mem_free;
}


+(unsigned int) getAppMemory {
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
