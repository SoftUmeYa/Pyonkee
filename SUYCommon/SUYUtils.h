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
+ (void) removeFilesMatches:(NSString*)regexString inPath:(NSString*)path;
+ (BOOL) belongsToTempDirectory: (NSString*) filePath;
+ (int) fileExists: (NSString*)fileName inDirectory: (NSString*)path;
+ (CGSize) scratchScreenSize;
+ (float) scratchScreenZoomScale;
+ (Class) squeakUIViewClass;
+ (NSString *)applicationSupportDirectory;
+ (NSString *)tempDirectory;
+ (NSString *)documentDirectory;
+ (NSString *)documentInboxDirectory;
+ (NSString *)bundleResourceDirectoryWith: (NSString*)subDir;
+ (NSString *)currentCountry;
+ (NSString *)currentLanguage;
+ (void) inform:(NSString*)message duration:(int)seconds for:(id)dele;
+ (void) alertWarning: (NSString*) msg;
+ (UIAlertController*) newAlert:(NSString*)message title: (NSString*)title;
+ (UIAlertController*) newAlert:(NSString*)message;
+ (UIAlertController*) newInfoAlert:(NSString*)message;
+ (void) printMemStats;
+ (NSArray*) supportedUtis;

@end
