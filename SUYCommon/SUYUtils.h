//
//  SUYUtils.h
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2014/04/10.
//
//

#import <Foundation/Foundation.h>
#import <MessageUI/MFMailComposeViewController.h>

@interface SUYUtils : NSObject
+ (BOOL) isIPad;
+ (BOOL) isRetina;
+ (BOOL) canSendMail;
+ (UIImage *)upsideDownImage:(UIImage*)origImage;
+ (CGRect) scratchScreenSize;
+ (float) scratchScreenZoomScale;
+ (Class) squeakUIViewClass;
+ (NSString *)applicationSupportDirectory;
+ (NSString *)tempDirectory;
+ (NSString *)bundleResourceDirectoryWith: (NSString*)subDir;
+ (void) inform:(NSString*)message duration:(int)seconds for:(id)dele;
+ (void) printMemStats;

@end
