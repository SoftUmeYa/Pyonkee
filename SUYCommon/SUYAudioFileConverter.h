//
//  SUYAudioFileConverter.h
//  Scratch
//
//  Created by Masashi UMEZAWA on 2018/09/03.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioToolbox/AudioConverter.h>
#import <AudioToolbox/ExtendedAudioFile.h>

@interface SUYAudioFileConverter : NSObject

-(NSString*)saveAiffFromPath: (NSString*) fromPath;
-(BOOL)saveAiffTo: (NSString*) fromPath reading:(NSString*) toPath;

@end
