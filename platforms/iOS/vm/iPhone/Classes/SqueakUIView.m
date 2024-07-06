//
//  SqueakUIView.m
//  SqueakNoOGLIPhone
//
//  Created by John M McIntosh on 5/20/08.
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
#import "SqueakUIView.h"
#import "sqSqueakMainApplication.h"
#import "SqueakNoOGLIPhoneAppDelegate.h"
#import "sqSqueakIPhoneApplication+events.h"
#import "sqiPhoneScreenAndWindow.h"
#import "sq.h"

extern struct	VirtualMachine* interpreterProxy;
extern SqueakNoOGLIPhoneAppDelegate *gDelegateApp;

@implementation SqueakUIView : UIView ;
@synthesize squeakTheDisplayBits;

CGPoint startPos;
CGPoint endPos;

- (id)initWithFrame:(CGRect) aFrame {
    self = [super initWithFrame: aFrame];
    // self.autoresizingMask = UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    colorspace = CGColorSpaceCreateDeviceRGB();
    
    self.multipleTouchEnabled = YES;
    
    //[self prepareLongPressGestureRecognizer];
    
    return self;
}

- (void) dealloc {
    [super dealloc];
    //	if (colorspace)
    //		CGColorSpaceRelease(colorspace);
}

- (void) preDrawThelayers{
}

- (void) drawThelayers {
}

- (void) drawImageUsingClip: (CGRect) clip {
}


#pragma mark EventHandling

// Handles the start of a touch
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    //Called by Main Thread, beware of calling Squeak routines in Squeak Thread
    //LgInfo(@"touches: %d ", touches.count);
    [[NSNotificationCenter defaultCenter] postNotificationName: @"SqueakUIViewTouchesBegan" object: self];
    [(sqSqueakIPhoneApplication *) gDelegateApp.squeakApplication recordTouchEvent: touches type: UITouchPhaseBegan];
}

// Handles the continuation of a touch.
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event 
{
    UITouch *touch = [touches anyObject];
    CGPoint nowPos = [touch locationInView:self];
    CGPoint prevPos =  [touch previousLocationInView:self];
    
    if([self distance:nowPos and:prevPos] < 1.5){
        return;
    }
    //Called by Main Thread, beware of calling Squeak routines in Squeak Thread
    [(sqSqueakIPhoneApplication *) gDelegateApp.squeakApplication recordTouchEvent: touches type: UITouchPhaseMoved];
    
}

- (CGFloat) distance: (CGPoint) p1 and: (CGPoint)p2
{
    CGFloat xDist = (p1.x - p2.x);
    CGFloat yDist = (p1.y - p2.y);
    CGFloat distance = sqrt((xDist * xDist) + (yDist * yDist));
    //NSLog(@" dist %f ", distance);
    return distance;
}

// Handles the end of a touch event.
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event 
{
    //Called by Main Thread, beware of calling Squeak routines in Squeak Thread
    [(sqSqueakIPhoneApplication *) gDelegateApp.squeakApplication recordTouchEvent: touches type: UITouchPhaseEnded];
}

- (void) touchesCancelled: (NSSet *) touches withEvent: (UIEvent *) event {
    //Called by Main Thread, beware of calling Squeak routines in Squeak Thread
    [(sqSqueakIPhoneApplication *) gDelegateApp.squeakApplication recordTouchEvent: touches type: UITouchPhaseCancelled];
}


- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan)
    {
        LgInfo(@"handleLongPressGesture");
        //[(sqSqueakIPhoneApplication *) gDelegateApp.squeakApplication recordTouchEvent: nil type: UITouchPhaseBegan];
        
    }
}

#pragma mark Testing

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)hasText {
    return YES;
}

#pragma mark Actions

- (void)insertText:(NSString *)text {
    [self recordCharEvent: text];
}

- (void)deleteBackward {
    unichar delete[1];
    delete[0] =  0x08;
    
    [self recordCharEvent:[NSString stringWithCharacters: delete length: 1]];
}

- (void) pushEventToQueue: (sqInputEvent *) evt {	
    NSMutableArray* data = [NSMutableArray new];
    [data addObject: [NSNumber numberWithInteger: 7]];
    [data addObject: [NSData  dataWithBytes:(const void *) evt length: sizeof(sqInputEvent)]];
    [[gDelegateApp.squeakApplication eventQueue]  addItem: data];
    [data release];
}

- (int) figureOutKeyCode: (unichar) unicode {
    static int unicodeToKeyCode[] = {54, 115, 11, 52, 119, 114, 3, 5, 51, 48, 38, 116, 121, 36, 45, 31,
        96, 12, 15, 1, 17, 32, 9, 13, 7, 16, 6, 53, 123, 124, 126, 125, 49, 18, 39, 20, 21, 23, 26, 39,
        25, 29, 67, 69, 43, 27, 47, 44, 29, 18, 19, 20, 21, 23, 22, 26, 28, 25, 41, 41, 43, 24, 47,
        44, 19, 0, 11, 8, 2, 14, 3, 5, 4, 34, 38, 40, 37, 46, 45, 31, 35, 12, 15, 1, 17, 32, 9, 13,
        7, 16, 6, 33, 42, 30, 22, 27, 50, 0, 11, 8, 2, 14, 3, 5, 4, 34, 38, 40, 37, 46, 45, 31, 35,
        12, 15, 1, 17, 32, 9, 13, 7, 16, 6, 33, 42, 30, 50, 117};
    if (unicode > 127)
        return 0;
    return unicodeToKeyCode[unicode];
    
}

- (void) recordKeyUpEvent:(NSString *) unicodeString {
    sqKeyboardEvent evt;
    unichar unicode;
    unsigned char macRomanCharacter;
    NSInteger    i;
    NSRange picker;
    NSUInteger totaLength;
    
    evt.type = EventTypeKeyboard;
    evt.timeStamp = (int) ioMSecs();
    picker.location = 0;
    picker.length = 1;
    totaLength = [unicodeString length];
    for (i=0;i < totaLength;i++) {
        
        unicode = [unicodeString characterAtIndex: i];
        NSString *lookupString = [[NSString alloc] initWithCharacters: &unicode length: 1];
        [lookupString getBytes: &macRomanCharacter maxLength: 1 usedLength: NULL encoding: NSMacOSRomanStringEncoding
                       options: 0 range: picker remainingRange: NULL];
        [lookupString release];
        
        // LF -> CR
        if (macRomanCharacter == 10)
            macRomanCharacter = 13;
        
        evt.pressCode = EventKeyUp;
        BOOL isUppercase = [[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember: unicode];
        evt.modifiers = isUppercase ? ShiftKeyBit : 0;
        evt.charCode = [self figureOutKeyCode: unicode];

        evt.utf32Code = 0;
        evt.reserved1 = 0;
        evt.windowIndex = 1;
        
        if ((evt.modifiers & CommandKeyBit) && (evt.modifiers & ShiftKeyBit)) {  /* command and shift */
            if ((unicode >= 97) && (unicode <= 122)) {
                /* convert ascii code of command-shift-letter to upper case */
                unicode = unicode - 32;
            }
        }
        
        evt.utf32Code = unicode;
        [self pushEventToQueue: (sqInputEvent *) &evt];
    }
    
    interpreterProxy->signalSemaphoreWithIndex(gDelegateApp.squeakApplication.inputSemaphoreIndex);
}

- (void) recordCharEvent:(NSString *) unicodeString modifiers: (unsigned int) modifiers autoKeyUp: (BOOL) autoKeyUp {
    [self basicRecordCharEvent:autoKeyUp modifiers:modifiers unicodeString: [unicodeString precomposedStringWithCanonicalMapping]];
    interpreterProxy->signalSemaphoreWithIndex(gDelegateApp.squeakApplication.inputSemaphoreIndex);
}

- (void) recordCharEvent:(NSString *) unicodeString {
    [self recordCharEvent: unicodeString modifiers:0 autoKeyUp:YES];
}

#pragma mark Private

- (void)basicRecordCharEvent:(BOOL)autoKeyUp modifiers:(unsigned int)modifiers unicodeString:(NSString *)unicodeString {
    NSRange fullRange = NSMakeRange(0, [unicodeString length]);
    [unicodeString enumerateSubstringsInRange:fullRange
                          options:NSStringEnumerationByComposedCharacterSequences
                       usingBlock:^(NSString *substring, NSRange substringRange,
                                    NSRange enclosingRange, BOOL *stop)
    {
        sqKeyboardEvent evt;
        unichar unicode;
        unsigned char macRomanCharacter;
        NSRange picker;
        
        evt.type = EventTypeKeyboard;
        evt.timeStamp = (int) ioMSecs();
        picker.location = 0;
        picker.length = 1;
        
        unicode = [substring characterAtIndex: 0];
        NSString *lookupString = [[NSString alloc] initWithCharacters: &unicode length: 1];
        [lookupString getBytes: &macRomanCharacter maxLength: 1 usedLength: NULL encoding: NSMacOSRomanStringEncoding
                       options: 0 range: picker remainingRange: NULL];
        [lookupString release];
        
        // LF -> CR
        if (macRomanCharacter == 10)
            macRomanCharacter = 13;
        
        evt.pressCode = EventKeyDown;
        BOOL isUppercase = [[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember: unicode];
        evt.modifiers = isUppercase ? ShiftKeyBit : modifiers;
        evt.charCode = [self figureOutKeyCode: unicode];
        
        unsigned int keyCodeRemembered = evt.charCode;
        evt.utf32Code = 0;
        evt.reserved1 = 0;
        evt.windowIndex = 1;
        [self pushEventToQueue: (sqInputEvent *)&evt];
        
        evt.charCode =    macRomanCharacter;
        evt.pressCode = EventKeyChar;
        evt.modifiers = evt.modifiers;
        if ((evt.modifiers & CommandKeyBit) && (evt.modifiers & ShiftKeyBit)) {  /* command and shift */
            if ((unicode >= 97) && (unicode <= 122)) {
                /* convert ascii code of command-shift-letter to upper case */
                unicode = unicode - 32;
            }
        }
        
        int utf32Code = unicode;
        if (substringRange.length >= 2) { //probably surrogate pair
            uint16_t lower = [substring characterAtIndex: 1];
            uint32_t code = [self utf32FromSurrogate:unicode lower:lower];
            if (code != 0){
                utf32Code = code; //detected surrogate pair
            }
        }
        evt.utf32Code = utf32Code;
        
        evt.timeStamp++;
        [self pushEventToQueue: (sqInputEvent *) &evt];
        
        if (autoKeyUp) {
            evt.pressCode = EventKeyUp;
            evt.charCode = keyCodeRemembered;
            evt.utf32Code = 0;
            evt.timeStamp++;
            [self pushEventToQueue: (sqInputEvent *) &evt];
        }
        
    }];
}

- (uint32_t)utf32FromSurrogate:(uint16_t) higher lower: (uint16_t) lower {
    if ((higher & 0xF800) != 0xD800 || (lower & 0xFC00) != 0xDC00) {
        return 0; // invalid surrogate pair
    }
    uint32_t codepoint = ((higher - 0xD800) << 10) + (lower - 0xDC00) + 0x10000;
    return codepoint;
}

- (void)prepareLongPressGestureRecognizer {
    // not used for now
//    UILongPressGestureRecognizer *longPressGestureRecog = [[UILongPressGestureRecognizer alloc]                                                  initWithTarget:self action:@selector(handleLongPressGesture:)];
//    longPressGestureRecog.cancelsTouchesInView = NO;
//    longPressGestureRecog.minimumPressDuration = 1.0;
//    longPressGestureRecog.allowableMovement = 10.0;
//    [self addGestureRecognizer:longPressGestureRecog];
//    [longPressGestureRecog release];
}

@end

