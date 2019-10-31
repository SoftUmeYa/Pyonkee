//
//  sqSqueakIPhoneInfoPlistInterface
//  SqueakNoOGLIPhone
//
//  Created by John M McIntosh on 9/1/08.
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

Sept-02-08  1.03b1  setup useScrollingView
*/
//

#import "sqSqueakIPhoneInfoPlistInterface.h"

NSString * kspaceRepeats_preference = @"spaceRepeats_preference";
NSString * kmemorySize_preferenceKey = @"memorySize_preference";
NSString * ktimeOut_preferenceKey = @"timeOut_preference";
NSString * kinboxMaxNumOfItems_preferenceKey = @"inboxMaxNumOfItems_preference";
NSString * kuseVirtualMIDI_preferenceKey = @"useVirtualMIDI_preference";

 extern int gSqueakUseFileMappedMMAP;

@implementation sqSqueakIPhoneInfoPlistInterface
- (void) parseInfoPlist {
	
	[super parseInfoPlist];
    
//	self.SqueakUseFileMappedMMAP = YES;
//	gSqueakUseFileMappedMMAP = 1;

    self.SqueakUseFileMappedMMAP = gSqueakUseFileMappedMMAP;
    
    NSArray* allKeys = [[defaults dictionaryRepresentation] allKeys];
    if([allKeys containsObject:kmemorySize_preferenceKey] == NO){
        [self setupDefaultValues];
    }
    
    NSLog(@"*** spaceRepeats: %ul, ", self.spaceRepeats);
//    NSLog(@"*** memorySize: %@, ", [NSNumber numberWithLong: self.memorySize]);
//    NSLog(@"*** inboxMaxNumOfItems: %@, ", [NSNumber numberWithLong: self.inboxMaxNumOfItems]);

}

- (void) setupDefaultValues {
    // no default values have been set, create them here based on what's in our Settings bundle info
    //
    NSString *pathStr = [[NSBundle mainBundle] bundlePath];
    NSString *settingsBundlePath = [pathStr stringByAppendingPathComponent:@"Settings.bundle"];
    NSString *finalPath = [settingsBundlePath stringByAppendingPathComponent:@"Root.plist"];
    
    NSDictionary *settingsDict = [NSDictionary dictionaryWithContentsOfFile:finalPath];
    NSArray *prefSpecifierArray = [settingsDict objectForKey:@"PreferenceSpecifiers"];
    NSDictionary *prefItem;
    
    for (prefItem in prefSpecifierArray)    {
        NSString *keyValueStr = [prefItem objectForKey:@"Key"];
        id defaultValue = [prefItem objectForKey:@"DefaultValue"];

        if(OVER_IOS13){
            NSNumber* adjustedDefaultValue;
            if ([keyValueStr isEqualToString: kmemorySize_preferenceKey]) {
                adjustedDefaultValue = [self adjustedSliderValue: defaultValue min: 41943040.0 max: 419430400.0];
                [defaults setObject: adjustedDefaultValue forKey:kmemorySize_preferenceKey];
            }
            if ([keyValueStr isEqualToString: kinboxMaxNumOfItems_preferenceKey]) {
                adjustedDefaultValue = [self adjustedSliderValue: defaultValue min: 100.0 max: 1000.0];
                [defaults setObject: adjustedDefaultValue forKey:kinboxMaxNumOfItems_preferenceKey];
            }
        } else {
            if ([keyValueStr isEqualToString: kmemorySize_preferenceKey]) {
                [defaults setObject: defaultValue forKey:kmemorySize_preferenceKey];
            }
            if ([keyValueStr isEqualToString: kinboxMaxNumOfItems_preferenceKey]) {
                [defaults setObject: defaultValue forKey:kinboxMaxNumOfItems_preferenceKey];
            }
        }
        
        if ([keyValueStr isEqualToString: kspaceRepeats_preference]) {
             [defaults setBool: YES forKey: kspaceRepeats_preference];
        }

        //do nothing if default value is NO
        if ([keyValueStr isEqualToString: kuseVirtualMIDI_preferenceKey]) {
        }

    }
    
    //For older iOS (before 11)
    [defaults synchronize];
}

- (double) adjustedAppValue:(double) rawSliderValue min: (double) min max: (double) max {
    return (rawSliderValue + min/(max-min)) * (max-min);
}

- (NSNumber*) adjustedSliderValue:(NSNumber*) rawAppValue min: (double) min max: (double) max {
    return [NSNumber numberWithDouble:(rawAppValue.doubleValue - min) / (max - min)];
}


#pragma mark - Accessing

- (NSInteger) memorySize {
    NSNumber* memSize = [defaults objectForKey: kmemorySize_preferenceKey];
    if(memSize.doubleValue <= 1){ //For iOS13
        double memAppValue = [self adjustedAppValue: memSize.doubleValue min: 41943040.0 max: 419430400.0];
        return memAppValue;
    }
    return memSize.integerValue;
}

- (NSInteger) inboxMaxNumOfItems {
    NSNumber* inboxSize = [defaults objectForKey:kinboxMaxNumOfItems_preferenceKey];
    if(inboxSize.doubleValue <= 1){ //For iOS13
        double inboxAppValue = [self adjustedAppValue: inboxSize.doubleValue min: 100.0 max: 1000.0];
        return inboxAppValue;
    }
    return inboxSize.integerValue;
}

- (BOOL) useVirtualMIDI {
    return [defaults boolForKey: kuseVirtualMIDI_preferenceKey];
}

- (BOOL) spaceRepeats {
    return [defaults boolForKey: kspaceRepeats_preference];
}


#pragma mark - Accessing - Obsolete

- (BOOL) imageIsWriteable {
    return NO;
}

- (BOOL) useScrollingView {
    return YES;
}

- (CGFloat) timeOut {
    return 30.0f;
}

#pragma mark - Debugging

- (void) printUserDefaults: (NSDictionary*)defs tag: (NSString*)tag {
    //For debug
    NSLog(@"-%@",tag);
    for (id key in defs)
    {
        NSLog(@"key: %@, value: %@", key, [defs objectForKey:key]);
    }
}

@end
