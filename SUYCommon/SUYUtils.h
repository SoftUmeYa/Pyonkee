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
+ (UIImage *)rotateRightImage:(UIImage*)origImage;
+ (UIImage *)rotateLeftImage:(UIImage*)origImage;
+ (void) trimResourcePathOnLaunch: (NSString*) resourcePath max: (int) max;
+ (CGSize) scratchScreenSize;
+ (float) scratchScreenZoomScale;
+ (Class) squeakUIViewClass;
+ (NSString *)applicationSupportDirectory;
+ (NSString *)tempDirectory;
+ (NSString *)bundleResourceDirectoryWith: (NSString*)subDir;
+ (NSString *)currentCountry;
+ (void) inform:(NSString*)message duration:(int)seconds for:(id)dele;
+ (void) alertWarning: (NSString*) msg;
+ (void) printMemStats;

@end
