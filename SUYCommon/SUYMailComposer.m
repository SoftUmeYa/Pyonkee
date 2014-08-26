//
//  SUYMailComposer.m
//  ScratchOnIPad
//
//  Created by Masashi UMEZAWA on 2014/07/26.
//
//  Extracted from ScratchIPhoneAppDelegate.m by John M McIntosh on 10-02-14.
//  Copyright 2010 Corporate Smalltalk Consulting Ltd. All rights reserved.

#import "SUYMailComposer.h"
#import "SUYUtils.h"

@implementation SUYMailComposer

BOOL isComposing = NO;
BOOL isForErrorReport = NO;

@synthesize	 viewController, brokenWalkBackString;

#pragma mark -
#pragma mark Mail
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)aError {
	UIAlertView *mailResult = [[UIAlertView alloc] init];
	NSString *ok = NSLocalizedString(@"OK",nil);
	switch(result) {
		case MFMailComposeResultSaved: {
			NSString *saved = NSLocalizedString(@"Saved",nil);
			NSString *savedMsg = NSLocalizedString(@"SavedMsg",nil);
 			mailResult.title = saved;
			mailResult.message = savedMsg;
			int indexOfButton = [mailResult addButtonWithTitle: ok];
			[mailResult dismissWithClickedButtonIndex:indexOfButton animated:YES];
			[self.viewController  dismissViewControllerAnimated:YES completion:NULL];
			[mailResult show];
			break;
		}
		case MFMailComposeResultFailed: {
			NSString *failed = NSLocalizedString(@"Failed",nil);
			NSString *failedMsg = NSLocalizedString(@"FailedMsg",nil);
			mailResult.title = failed;
			mailResult.message = failedMsg;
			int indexOfButton = [mailResult addButtonWithTitle: ok];
			[mailResult dismissWithClickedButtonIndex:indexOfButton animated:YES];
			[self.viewController dismissViewControllerAnimated:YES completion:NULL];
			[mailResult show];
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
    if(isComposing == YES){return;}
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
	NSData *data2 = [self dumpConsoleLog];
	NSData *datazipped2 = [LFCGzipUtility gzipData: data2];
	[emailController addAttachmentData: datazipped2 mimeType: @"application/octet-stream" fileName: @"DiagnosticsInformationLog.bin"];
    self.viewController.modalPresentationStyle = UIModalPresentationPageSheet;
	[self.viewController presentViewController: emailController animated:YES completion:NULL];
}


- (void) mailProject: (NSString *)projectPath{
    if (!([SUYUtils canSendMail])){return;}
    if(isComposing == YES){return;}
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
	[self.viewController presentViewController: emailController animated:YES completion:NULL];
}

#pragma mark -
#pragma mark Releasing

- (void) abort {
    if(isComposing){
        [self.viewController dismissViewControllerAnimated:YES completion:NULL];
    }
}

#pragma mark -
#pragma mark Log
- (NSData *) dumpConsoleLog {
	NSMutableString *dumpString = [[NSMutableString alloc] init];
	
	//Build a query message containing all our criteria.
	aslmsg query = asl_new(ASL_TYPE_QUERY);
	//Specify one or more criteria with calls to asl_set_query.
    
	
    asl_set_query(query, ASL_KEY_MSG, "com.softumeya.Pyonkee", ASL_QUERY_OP_EQUAL);
	
	//Begin the search.
	aslresponse response = asl_search(NULL,query);
	
	//We don't need this anymore.
	asl_free(query);
	
	aslmsg msg;
	while ((msg = aslresponse_next(response))) {
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
	
	aslresponse_free(response);
	NSData *data = [dumpString dataUsingEncoding: NSUTF8StringEncoding];
	return data;
}

@end
