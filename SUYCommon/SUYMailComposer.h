//
//  SUYMailComposer.h
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2014/07/26.
//
//

#import <Foundation/Foundation.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "LFCGzipUtility.h"
#import <asl.h>
#import <mach/mach_host.h>
#import <sys/sysctl.h>

@interface SUYMailComposer : NSObject<MFMailComposeViewControllerDelegate>{
    
}

@property (nonatomic, weak) UINavigationController *viewController;
@property (nonatomic, strong) NSString *brokenWalkBackString;

- (void) reportErrorByEmail;
- (void) mailProject: (NSString *)projectPath;
- (void) abort;

@end
