//
//  SUYAudioFileConverter.m
//  Scratch
//
//  Created by Masashi UMEZAWA on 2018/09/03.
//

#import "SUYUtils.h"
#import "SUYAudioFileConverter.h"

@implementation SUYAudioFileConverter

static UInt32 _FrameSize = 1024;

-(AudioStreamBasicDescription) outputAiffDescription
{
    AudioStreamBasicDescription outputFormat;
    outputFormat.mSampleRate         = 22050.0;
    outputFormat.mFormatID            = kAudioFormatLinearPCM;
    outputFormat.mFormatFlags        = kAudioFormatFlagIsBigEndian
    | kLinearPCMFormatFlagIsSignedInteger
    | kLinearPCMFormatFlagIsPacked;
    outputFormat.mFramesPerPacket    = 1;
    outputFormat.mChannelsPerFrame    = 2;
    outputFormat.mBitsPerChannel    = 16;
    outputFormat.mBytesPerPacket    = 4;
    outputFormat.mBytesPerFrame        = 4;
    outputFormat.mReserved            = 0;
    
    return outputFormat;
}

#pragma mark Actions

-(NSString*)saveAiffFromPath: (NSString*) fromPath
{
    NSString* toPath = [self targetPathForFileName:[self newFileName]];
    if([self saveAiffTo: toPath reading: fromPath] == NO){ return fromPath;}
    return toPath;
}

-(BOOL)saveAiffTo: (NSString*) toPath reading:(NSString*) fromPath
{
    NSURL* fromUrl = [NSURL fileURLWithPath: fromPath];
    NSURL* toUrl = [NSURL fileURLWithPath: toPath];
    
    return [self convertFrom: fromUrl toURL: toUrl];
}

-(BOOL)convertFrom:(NSURL*)fromURL toURL:(NSURL*)toURL
{
    [SUYUtils removeFilesMatches: @".*-converted\\.aiff" inPath:[SUYUtils tempDirectory]];
    return [self convertFrom:fromURL toURL:toURL format:[self outputAiffDescription]];
}

#pragma mark Converting

-(BOOL)convertFrom:(NSURL*)fromURL
             toURL:(NSURL*)toURL
            format:(AudioStreamBasicDescription)outputFormat
{
    OSStatus err;
    ExtAudioFileRef infile,outfile;
    
    err = ExtAudioFileOpenURL((__bridge CFURLRef)fromURL, &infile);
    if([self hasError:err message:@"ExtAudioFileOpenURL"]) {return NO;}
    
    err = ExtAudioFileSetProperty(infile,
                                  kExtAudioFileProperty_ClientDataFormat,
                                  sizeof(AudioStreamBasicDescription),
                                  &outputFormat);
    if([self hasError:err message:@"ExtAudioFileSetProperty"]) {return NO;}
    
    err = ExtAudioFileCreateWithURL((__bridge CFURLRef)toURL,
                                    kAudioFileAIFFType,
                                    &outputFormat,
                                    NULL,
                                    kAudioFileFlags_EraseFile,
                                    &outfile);
    if([self hasError:err message:@"ExtAudioFileCreateWithURL"]) {return NO;}
    
    err = ExtAudioFileSeek(infile, 0);
    if([self hasError:err message:@"ExtAudioFileSeek"]) {return NO;}
    
    UInt32 readFrameSize = _FrameSize;
    
    UInt32 bufferSize = sizeof(char) * readFrameSize * outputFormat.mBytesPerPacket;
    char *buffer = malloc(bufferSize);
    
    AudioBufferList audioBufferList;
    audioBufferList.mNumberBuffers = 1;
    audioBufferList.mBuffers[0].mNumberChannels = outputFormat.mChannelsPerFrame;
    audioBufferList.mBuffers[0].mDataByteSize = bufferSize;
    audioBufferList.mBuffers[0].mData = buffer;
    
    while(YES){
        readFrameSize = _FrameSize;
        err = ExtAudioFileRead(infile, &readFrameSize, &audioBufferList);
        if([self hasError:err message:@"ExtAudioFileRead"]) {return NO;}
        
        if(readFrameSize == 0)break;
        
        err = ExtAudioFileWrite(outfile,
                                readFrameSize,
                                &audioBufferList);
        if([self hasError:err message:@"ExtAudioFileWrite"]) {return NO;}
    }
    
    ExtAudioFileDispose(infile);
    ExtAudioFileDispose(outfile);
    free(buffer);
    return YES;
}

#pragma mark Private

- (NSString *)targetPathForFileName:(NSString *)name
{
    NSString *path = [SUYUtils tempDirectory];
    return [path stringByAppendingPathComponent:name];
}

- (NSString *)newFileName
{
    NSDate* now = [NSDate date];
    NSInteger intMillSec = (NSInteger) floor([now timeIntervalSinceReferenceDate]);
    NSString* strNow = [NSString stringWithFormat:@"%ld%02d-converted.aiff", (long)intMillSec, 1];
    return strNow;
}

- (BOOL) hasError: (OSStatus )err message: (NSString*)message
{
    if(err){
        NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil];
        LgError(@"%@ = %@,%d",message, error.localizedDescription,(int)err);
        return YES;
    }
    return NO;
}

@end
