//
//  SUYUtils.h
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2014/04/10.
//
//

#import <Foundation/Foundation.h>
#import <MessageUI/MFMailComposeViewController.h>

#import <SDCAlertView/SDCAlertView.h>

@interface SUYUtils : NSObject
+ (BOOL) isIPadIdiom;
+ (BOOL) isRetina;
+ (BOOL) isOnMac;
+ (BOOL) canSendMail;
+ (UIImage *)upsideDownImage:(UIImage*)origImage;
+ (UIImage *)rotateRightImage:(UIImage*)origImage;
+ (UIImage *)rotateLeftImage:(UIImage*)origImage;
+ (UIImage *)offsetImage:(UIImage*)origImage transposed: (CGRect) rect offset: (CGPoint) offset size: (CGSize) size;
+ (void) trimResourcePathOnLaunch: (NSString*) resourcePath max: (int) max;
+ (void) removeFilesMatches:(NSString*)regexString inPath:(NSString*)path;
+ (BOOL) belongsToTempDirectory: (NSString*) filePath;
+ (int) fileExists: (NSString*)fileName inDirectory: (NSString*)path;
+ (CGSize) rootViewSizeOf: (UIView *)view;
+ (CGSize) scratchScreenSize;
+ (float) scratchScreenZoomScale;
+ (UIInterfaceOrientation) interfaceOrientation;
+ (Class) squeakUIViewClass;
+ (NSString *)applicationSupportDirectory;
+ (NSString *)tempDirectory;
+ (NSString *)documentDirectory;
+ (NSString *)documentInboxDirectory;
+ (NSString *)bundleResourceDirectoryWith: (NSString*)subDir;
+ (NSString *)currentCountry;
+ (CGFloat) landscapeScreenHeight;
+ (NSString *)currentLanguage;
+ (void) inform:(NSString*)message duration:(int)seconds;
+ (void) alertWarning: (NSString*) msg;
+ (void) alertInfo: (NSString*) msg;
+ (SDCAlertController*) newAlert:(NSString*)message title: (NSString*)title;
+ (SDCAlertController*) newInfoAlert:(NSString*)message title: (NSString*)title;
+ (void) printMemStats;
+ (NSArray*) supportedUtis;
+ (void) showCursor:(int)cursorCode;
+ (void) hideCursor;
+ (BOOL) cursorEnabled;
+ (void) showToast: (NSString*) message image: (UIImage*) image title: (NSString*) title;
+ (void) showToastOn:(UIView*) view message:(NSString*) message image: (UIImage*) image title: (NSString*) title;
+ (void) showActivityToastOn:(UIView*) view;
+ (void) hideActivityToastOn:(UIView*) view;
+ (NSString*)saveAiffFromPath: (NSString*) fromPath;

@end
