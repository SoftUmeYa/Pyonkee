//
//  SUYMailComposer.m
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2014/07/26.
//
//  Extracted from SUYScratchAppDelegate.m by John M McIntosh on 10-02-14.
//  Copyright 2010 Corporate Smalltalk Consulting Ltd. All rights reserved.

#import "SUYMailComposer.h"
#import "SUYUtils.h"

#import <SDCAlertView/SDCAlertView.h>

@implementation SUYMailComposer

BOOL isComposing = NO;
BOOL isForErrorReport = NO;

#pragma mark -
#pragma mark Mail
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)aError {
	switch(result) {
		case MFMailComposeResultSaved: {
			NSString *saved = NSLocalizedString(@"Saved",nil);
			NSString *savedMsg = NSLocalizedString(@"SavedMsg",nil);
            SDCAlertController *alert = [SUYUtils newInfoAlert:savedMsg title:saved];
            [self.viewController dismissViewControllerAnimated:YES completion:NULL];
            [self.viewController presentViewController:alert animated:YES completion:nil];
 			break;
		}
		case MFMailComposeResultFailed: {
			NSString *failed = NSLocalizedString(@"Failed",nil);
			NSString *failedMsg = NSLocalizedString(@"FailedMsg",nil);
            SDCAlertController *alert = [SUYUtils newInfoAlert:failed title:failedMsg];
            [self.viewController dismissViewControllerAnimated:YES completion:NULL];
            [self.viewController presentViewController:alert animated:YES completion:nil];
			break;
		}
		default:
			[self.viewController dismissViewControllerAnimated:YES completion:NULL];
	}
    isComposing = NO;
    if(isForErrorReport==YES){
        isForErrorReport = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName: @"errorMailReported" object: nil];
    }
}

- (void) reportErrorByEmail {
	if (!([SUYUtils canSendMail])){return;}
    if(isComposing == YES){[self abort];}
    isComposing = YES;
    isForErrorReport = YES;
	NSString *helpEmailAddress = NSLocalizedString(@"helpEmailAddress",nil);
	NSString *helpSubject = NSLocalizedString(@"helpSubject",nil);
	NSString *helpMessage = NSLocalizedString(@"helpMessage",nil);
	MFMailComposeViewController *emailController = [[MFMailComposeViewController alloc] init];
	emailController.mailComposeDelegate = self;
	[emailController setToRecipients: [NSArray arrayWithObject: helpEmailAddress]];
	[emailController setSubject: helpSubject];
	[emailController setMessageBody: helpMessage isHTML: NO];
    NSData *data = [self.brokenWalkBackString dataUsingEncoding: NSUTF8StringEncoding];
	NSData *datazipped = [LFCGzipUtility gzipData: data];
	[emailController addAttachmentData: datazipped mimeType: @"application/octet-stream" fileName: @"DiagnosticsInformationWB.bin"];
    NSData *data2 = nil; //[self dumpConsoleLog]; //TODO: Use Unified logging for iOS 10
    if(data2){
        NSData *datazipped2 = [LFCGzipUtility gzipData: data2];
        [emailController addAttachmentData: datazipped2 mimeType: @"application/octet-stream" fileName: @"DiagnosticsInformationLog.bin"];
    }
    self.viewController.modalPresentationStyle = UIModalPresentationPageSheet;
	[self.viewController presentViewController: emailController animated:YES completion:NULL];
}


- (void) mailProject: (NSString *)projectPath{
    if (!([SUYUtils canSendMail])){
        LgInfo(@"----can not send mail-------");
        return;
    }
    if(isComposing == YES){[self abort];}
    isComposing = YES;
    isForErrorReport = NO;
    NSString *projName = [projectPath lastPathComponent];
    NSString *subject = NSLocalizedString(@"projectSendMailSubject",nil);
    subject = [subject stringByAppendingFormat: @" %@", projName];
	NSString *message = NSLocalizedString(@"projectSendMailMessage",nil);
	MFMailComposeViewController *emailController = [[MFMailComposeViewController alloc] init];
	emailController.mailComposeDelegate = self;
	[emailController setSubject: subject];
	[emailController setMessageBody: message isHTML: NO];
    NSData *data = [[NSData alloc] initWithContentsOfFile: projectPath];
	[emailController addAttachmentData: data mimeType: @"application/octet-stream" fileName: projName];
    self.viewController.modalPresentationStyle = UIModalPresentationPageSheet;
    [self.viewController presentViewController: emailController animated:YES completion:nil];
}

#pragma mark -
#pragma mark Releasing

- (void) abort {
    if(isComposing){
        [self.viewController dismissViewControllerAnimated:YES completion:NULL];
    }
    isComposing = NO;
}

#pragma mark -
#pragma mark Log
- (NSData *) dumpConsoleLog {
    
    NSMutableString *dumpString = [[NSMutableString alloc] init];
	
	//Build a query message containing all our criteria.
	aslmsg query = asl_new(ASL_TYPE_QUERY);
    
	//Specify one or more criteria with calls to asl_set_query
    asl_set_query(query, ASL_KEY_MSG, "com.softumeya.Pyonkee", ASL_QUERY_OP_EQUAL);
	
	//Begin the search.
	aslresponse response = asl_search(NULL,query);
	
	//We don't need this anymore.
	//asl_free(query);
	
	aslmsg msg;
	while ((msg = asl_next(response))) {
		//Do something with the message. For example, to iterate all its key-value pairs:
		const char *key;
		for (unsigned i = 0U; (key = asl_key(msg, i)); ++i) {
			const char *value = asl_get(msg, key);
			
			//Example: Print the key-value pair to stdout, with a tab between the key and the value.
			if (strcmp(key,"Message") == 0) {
				[dumpString appendFormat: @"%s\n",value];
			}
		}
		
		//Don't call asl_free for the message. The response owns it and will free it itself.
	}
	
	asl_free(response);
    
	NSData *data = [dumpString dataUsingEncoding: NSUTF8StringEncoding];
	return data;
}

@end
