//
//  TITextStorage.h
//  TypeIs0.5
//
//  Created by Travis Kirton on 10-03-02.
//  Copyright 2010 Kirton/Buza. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TIString.h"

/*
 NOTE:	Allows traversing a complete text
		Allows reading multiple text sources
		Cleans up data, etc...
 */

@interface TITextStorage : NSObject { 
	NSTextStorage	*mTextStorage;
	NSMutableArray	*mParagraphs;
	CFIndex			currentParagraph;
	CFIndex			nextAvailableParagraph;
	CFBooleanRef	hasContent;
}

#pragma mark initialization methods
-(id)_init;
+(TITextStorage *)sharedManager;

-(void)initWithBYTES:(const void *)bytes length:(NSUInteger)length encoding:(NSStringEncoding)encoding;
-(void)initWithCHARS:(const unichar *)characters length:(NSUInteger)length;
-(void)initWithCSTRING:(const char *)nullTerminatedCString encoding:(NSStringEncoding)encoding;
-(void)initWithDATA:(NSData *)data;
-(void)initWithDOC:(NSData *)data;
-(void)initWithFILE:(NSString *)path encoding:(NSStringEncoding)encoding;
-(void)initWithHTML:(NSData *)data;
-(void)initWithRTF:(NSURL *)rtfURL;
-(void)initWithSTRING:(NSString *)string;
-(void)initWithURL:(NSURL *)URL;
-(void)initWithUTF8STRING:(const char *)bytes;
-(void)initWithTextStorage:(TITextStorage *)textStorage;

#pragma mark data manipulation
-(void)initializeDataContainers;
-(void)cleanUpData;
-(CFIndex)indexOfNextAvailableParagraph;
-(TIString *)nextAvailableParagraph;

#pragma mark print methods
-(void)printData;
-(void)printParagraphs;
-(void)printParagraphsByCharacter;
-(void)printFirstParagraph;
-(void)printCFStringRef:(CFStringRef)str;
-(void)printLayoutManagers;
#pragma mark accessor methods
-(CFBooleanRef)hasContent;
-(CFIndex)currentParagraphIndex;
-(CFIndex)nextAvailableParagraphIndex;
@end
