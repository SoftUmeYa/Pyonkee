//
//  sqSqueakIPhoneApplication+imageReadWrite.m
//  SqueakNoOGLIPhone
//
//  Created by John M McIntosh on 5/22/08.
/*
 Some of this code was funded via a grant from the European Smalltalk User Group (ESUG)
 Copyright (c) 2008 Corporate Smalltalk Consulting Ltd. All rights reserved.
 MIT License
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 
 The end-user documentation included with the redistribution, if any, must include the following acknowledgment: 
 "This product includes software developed by Corporate Smalltalk Consulting Ltd (http://www.smalltalkconsulting.com) 
 and its contributors", in the same place and form as other third-party acknowledgments. 
 Alternately, this acknowledgment may appear in the software itself, in the same form and location as other 
 such third-party acknowledgments.
 */

//

#import "sqSqueakIPhoneApplication+imageReadWrite.h"
#import "sqMacV2Memory.h"
#import "sqSqueakIPhoneInfoPlistInterface.h"

#import "sqSqueakVmAndImagePathAPI.h"

@implementation sqSqueakIPhoneApplication (imageReadWrite) 

- (void) findImageViaBundleOrPreferences {
	NSAutoreleasePool * pool = [NSAutoreleasePool new];
	NSFileManager *dfm = [NSFileManager defaultManager];
	NSString* documentsPath = [dfm currentDirectoryPath];  //This should point to the Documents folder via a previous setup
	NSString* documentsImagePath = [documentsPath stringByAppendingPathComponent: @"Scratch.image"];
	NSString* documentsSourcesPath = [documentsPath stringByAppendingPathComponent: @"SqueakV2.sources"];

	//	NSString* documentsImagePath = [documentsPath stringByAppendingPathComponent: @"iPhone.image"];
//	NSString* documentsSourcesPath = [documentsPath stringByAppendingPathComponent: @"SqueakV39.sources"];
//	NSString* documentsSourcesPath = [documentsPath stringByAppendingPathComponent: @"PharoV10.sources"];

	BOOL fileExists = [dfm fileExistsAtPath: documentsImagePath], sourcesFileIsReadable,sourcesFileExists,copyOk,removeOK;
	NSError* error;
	
	/* At this point we copy over the image/changes/sources if they do not exist in Documents
	 however it appears the simulator logic caches things in the "iPhone Simulator" folder
	 between builds and is not cleaned by clean all, also you must delete the app on the iPhone
	 when doing development. Not sure how this will work for production. Do not know where
	 Apple syncs the iphone data to via iTunes yet */
	
	const char	*imageNameCharactersInDocumentPath = [dfm fileSystemRepresentationWithPath: documentsImagePath];
    
    applyImageNamePutLength(imageNameCharactersInDocumentPath, (sqInt)strlen(imageNameCharactersInDocumentPath));
    
	NSString * likelySourceFilePath = [dfm destinationOfSymbolicLinkAtPath: documentsSourcesPath error: &error];

	if (likelySourceFilePath) {
		sourcesFileExists = true;
		sourcesFileIsReadable = [dfm isReadableFileAtPath: documentsSourcesPath];
	} else {
		sourcesFileExists = false;
		sourcesFileIsReadable = false;
	}
	
	if (sourcesFileExists && !sourcesFileIsReadable) {
		sourcesFileExists = false;
		removeOK = [dfm removeItemAtPath: documentsSourcesPath error: &error];
	}
	
	if (!sourcesFileExists) {
		NSString* bundleSourcesPath = [[NSBundle mainBundle] pathForResource:@"SqueakV2" ofType:@"sources"];
		if (bundleSourcesPath) 
			copyOk = [dfm createSymbolicLinkAtPath: documentsSourcesPath withDestinationPath: bundleSourcesPath error: &error];
	}
	
	if (fileExists) {
		[pool drain];
		return;
	} else {

		NSString* bundleImagePath = [[NSBundle mainBundle] pathForResource:@"Scratch" ofType:@"image"]; 
		BOOL writeable = [(sqSqueakIPhoneInfoPlistInterface*)[self infoPlistInterfaceLogic] imageIsWriteable];
		
		if (writeable) {
			NSString* documentsChangesPath = [documentsPath stringByAppendingPathComponent: @"Scratch.changes"];
			NSString* bundleChangesPath = [[NSBundle mainBundle] pathForResource:@"Scratch" ofType:@"changes"];
			
			copyOk = [dfm copyItemAtPath: bundleImagePath toPath: documentsImagePath error: &error];
			if (!copyOk) {
				[pool drain];
				return;
			}
			copyOk = [dfm copyItemAtPath: bundleChangesPath toPath: documentsChangesPath error: &error];
		} else {
			const char	*imageNameCharacters = [dfm fileSystemRepresentationWithPath: bundleImagePath];
			applyImageNamePutLength(imageNameCharacters, strlen(imageNameCharacters));
		}
	}
	[pool drain];
}

int applyImageNamePutLength(const char* name, size_t length){
#if __LP64__
    return imageNameConstPutLength(name, length);
#else
    return imageNamePutLength((sqInt)name, (sqInt)length);
#endif
}


@end
