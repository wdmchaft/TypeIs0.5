//
//  TITextStorage.m
//  TypeIs0.5
//
//  Created by Travis Kirton on 10-03-02.
//  Copyright 2010 TypeIs - Kirton/Buza 2010. All rights reserved.
//

#import "TITextStorage.h"

static TITextStorage *myTITextStorage;

@implementation TITextStorage
GENERATE_SINGLETON(TITextStorage, myTITextStorage);

-(id)_init {
	[self initializeDataContainers];
	hasContent = kCFBooleanFalse;
	return self;
}

#pragma mark initialization methods
-(void)initWithBYTES:(const void *)bytes length:(NSUInteger)length encoding:(NSStringEncoding)encoding {
	NSString *aString = [[[NSString alloc] initWithBytes:bytes length:length encoding:encoding] autorelease];
	[self initWithSTRING:aString];
}

-(void)initWithCHARS:(const unichar *)characters length:(NSUInteger)length {
	NSString *aString = [[[NSString alloc] initWithCharacters:characters length:length] autorelease];
	[self initWithSTRING:aString];
}

-(void)initWithCSTRING:(const char *)nullTerminatedCString encoding:(NSStringEncoding)encoding {
	NSString *aString = [[[NSString alloc] initWithCString:nullTerminatedCString encoding:encoding] autorelease];
	[self initWithSTRING:aString];
}

-(void)initWithDATA:(NSData *)data {
	[self initializeDataContainers];
	[[mTextStorage initWithData:data options:nil documentAttributes:nil error:nil] retain];
	[self cleanUpData];
}

-(void)initWithDOC:(NSData *)data {
	[self initializeDataContainers];
	[[mTextStorage initWithDocFormat:data documentAttributes:nil] retain];
	[self cleanUpData];
}

-(void)initWithFILE:(NSString *)path encoding:(NSStringEncoding)encoding {
	NSString *aString = [[[NSString alloc] initWithContentsOfFile:path encoding:encoding error:nil] retain];
	[self initWithSTRING:aString];
}

-(void)initWithHTML:(NSData *)data {
	[self initializeDataContainers];
	[[mTextStorage initWithHTML:data documentAttributes:nil] retain];
	[self cleanUpData];
}

-(void)initWithRTF:(NSURL *)rtfURL {
	[self initializeDataContainers];
	[[mTextStorage initWithRTF:[NSData dataWithContentsOfURL:rtfURL] documentAttributes:nil] retain];
	[self cleanUpData];
}

-(void)initWithSTRING:(NSString *)aString {
	[self initializeDataContainers];
	[[mTextStorage initWithString:aString] retain];
	[self cleanUpData];
}

-(void)initWithURL:(NSURL *)URL {
	[self initializeDataContainers];
	[[mTextStorage initWithURL:URL documentAttributes:nil] retain];
	[self cleanUpData];
}

-(void)initWithUTF8STRING:(const char *)bytes {
	NSString *aString = [[[NSString alloc] initWithUTF8String:bytes] autorelease];
	[self initWithSTRING:aString];
}

#pragma mark data manipulation
-(void)initializeDataContainers {
	if (mTextStorage != nil) {
		[mTextStorage release];
		[mParagraphs removeAllObjects];
		[mParagraphs release];
	}
	mTextStorage = [[[NSTextStorage alloc] init] retain];
	mParagraphs = [[[NSMutableArray alloc] initWithCapacity:0] retain];
}

-(void)cleanUpData {
	NSArray *tempArray = [[NSArray alloc] initWithArray:[mTextStorage paragraphs]];
	for(int i = 0; i < [tempArray count]; i++){
		NSString *aString = [[[[tempArray objectAtIndex:i] mutableString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByAppendingString:@" "];
		if([aString length] > 3){
			TIString *aTIString = [[[TIString alloc] initWithNSString:[aString uppercaseString]] autorelease];
			[mParagraphs addObject:aTIString];
		}
	}
	hasContent = kCFBooleanTrue;
	currentParagraph = -1;
//	nextAvailableParagraph = [self indexOfNextAvailableParagraph];
	//printf("message");
	//[self printParagraphsByCharacter];
	//[self printParagraphs];
	[self printData];
	//[self printFirstParagraph];
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"TITextStorageDidCleanUpData" object:self]];
}

-(CFBooleanRef)isTextComplete {
	if (currentParagraph == [mParagraphs count]) {
		return kCFBooleanTrue;
	}
	return kCFBooleanFalse;
}

-(CFIndex)indexOfNextAvailableParagraph {
	if (currentParagraph == [mParagraphs count] ) {
		CFIndex i = 0;
		for(; i< [mParagraphs count]; i++){
			[[mParagraphs objectAtIndex:i] reset];
		}
		currentParagraph = -1;
		nextAvailableParagraph = 0;
	} else if(currentParagraph != -1 && [[mParagraphs objectAtIndex:currentParagraph] beingUsed] == kCFBooleanFalse && [[mParagraphs objectAtIndex:currentParagraph] complete] == kCFBooleanFalse) {
		return currentParagraph;
	} else {		
		CFIndex currParagraph = currentParagraph+1;
		for(currParagraph; currParagraph < [mParagraphs count]; currParagraph++){
			if ([[mParagraphs objectAtIndex:currParagraph] beingUsed] == kCFBooleanFalse && [[mParagraphs objectAtIndex:currParagraph] complete] == kCFBooleanFalse) {
				nextAvailableParagraph = currParagraph;
				break;
			}
		} 
		currentParagraph++;
	}
	return nextAvailableParagraph;
}

-(TIString *)nextAvailableParagraph {	
	return (TIString *)[mParagraphs objectAtIndex:[self indexOfNextAvailableParagraph]];
}

#pragma mark print methods
-(void)printData {
	int paragraphCount, wordCount, characterCount;
	paragraphCount = [[mTextStorage paragraphs] count];
	wordCount = [[mTextStorage words] count];
	characterCount = [[mTextStorage characters] count];
	
	printf("p:%d w:%d c:%d\n",paragraphCount,wordCount,characterCount);
	return;
}

-(void)printParagraphs {
	int paragraphCount;
	paragraphCount = [mParagraphs count];
	
	printf("p:%d\n",paragraphCount);
	
	for(int i = 0; i < paragraphCount; i++){
		NSLog(@"%d - %@",[[mParagraphs objectAtIndex:i] totalCharacters],(NSString *)[[mParagraphs objectAtIndex:i] completeString]);
	}
}

/*
 Simulates running through each paragraph, one character at a time, looking for the next available paragraph when one is complete
 NOTE: Messes with caret positions.
 */
-(void)printParagraphsByCharacter {
	int paragraphCount;
	paragraphCount = [mParagraphs count];
	
	printf("p:%d\n",paragraphCount);
	
	while ([self isTextComplete] == kCFBooleanFalse) {
		printf("new paragraph (%d): ",(int)currentParagraph);
		while ([[mParagraphs objectAtIndex:currentParagraph] complete] == kCFBooleanFalse) {
			CFStringRef charStringRef = [[mParagraphs objectAtIndex:currentParagraph] nextCharacterAsCFStringRef];
			[self printCFStringRef:charStringRef];
		}
		currentParagraph++;
		nextAvailableParagraph = [self indexOfNextAvailableParagraph];
		printf("\n");
	}
}

-(void)printFirstParagraph {
	while ([[mParagraphs objectAtIndex:0] complete] == kCFBooleanFalse) {
		CFStringRef charStringRef = [[mParagraphs objectAtIndex:0] nextCharacterAsCFStringRef];
		[self printCFStringRef:charStringRef];
	}
}

-(void)printCFStringRef:(CFStringRef)str {
	CFStringRef resultString;
	CFDataRef data;
	
	resultString = CFStringCreateWithFormatAndArguments(NULL, NULL, 
														str, NULL);	
	data = CFStringCreateExternalRepresentation(NULL, str, 
												CFStringGetSystemEncoding(), '?');
	
	if (data != NULL) {
		printf ("%.*s", (int)CFDataGetLength(data), 
				CFDataGetBytePtr(data));
		CFRelease(data);
	}
	CFRelease(resultString);
}

-(void)printLayoutManagers {
	printf("LAYOUT MANAGERS");
	printf("[%d]\n", (int)[[mTextStorage layoutManagers ]count]);
}
#pragma mark accessor methods
-(CFBooleanRef)hasContent {
	return hasContent;
}
@end
