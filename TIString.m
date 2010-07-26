//
//  TIString.m
//  TypeIs0.5
//
//  Created by collab-macpro on 10-03-08.
//  Copyright 2010 Travis Kirton. All rights reserved.
//

#import "TIString.h"

@interface TIString (private)
-(void)printCFStringRef:(CFStringRef)str;
@end

@implementation TIString

#pragma mark initialization and dealloc
-(id)init {
	return [self initWithCFStringRef:CFSTR("empty string")];
}

-(id)initWithCFStringRef:(CFStringRef)stringRef {
	if (![super init]) {
		return nil;
	}
	string = CFStringCreateCopy(kCFAllocatorDefault, stringRef);
	totalCharacters = CFStringGetLength(string);
	caretPosition = -1;
	beingUsed = NO;
	complete = NO;

	CFRetain(string);
	return self;
}

-(id)initWithNSString:(NSString *)nsstring {
	return [self initWithCFStringRef:(CFStringRef)nsstring];
}

-(void)dealloc {
	CFRelease(string);
	[super dealloc];
}

#pragma mark accessor functions
-(CFIndex)totalCharacters {
	return totalCharacters;
}

-(CFIndex)caretPosition {
	return caretPosition;
}

/*
 Returns whether or not this string is currently being used
 e.g. when looking for the next available string, the system should look for beingUsed == false && complete == false
 */
-(CFBooleanRef)beingUsed {
	if(beingUsed == kCFBooleanTrue) return kCFBooleanTrue;
	return kCFBooleanFalse;
}

/*
 Returns true if the entire string has been iterated through
 */
-(CFBooleanRef)complete {
	if(complete == kCFBooleanTrue) return kCFBooleanTrue;
	return kCFBooleanFalse;
}

/*
 Sets the value of beingUsed
 */
-(void)setBeingUsed:(CFBooleanRef)aBool {
	beingUsed = aBool;
}

/*
 Returns a copy of the complete string
 */
-(CFStringRef)completeString {
	return CFStringCreateCopy(kCFAllocatorDefault, string);
}

/*
 Returns a copy of the string used up to the caret position
 */
-(CFStringRef)usedString {
	return CFStringCreateWithSubstring(kCFAllocatorDefault, string, CFRangeMake(0, caretPosition));
}

/*
 Returns a copy of the string from the caret position to the end of the string
 */
-(CFStringRef)remainingString {
	return CFStringCreateWithSubstring(kCFAllocatorDefault, string, CFRangeMake(caretPosition, totalCharacters));
}

/*
 Returns a CTLineRef containing the current character
 */
-(CTLineRef)currCharacterAsLineRef {
	if(caretPosition == -1) caretPosition++;
	if(beingUsed == kCFBooleanFalse) beingUsed = kCFBooleanTrue;
	CFStringRef character = CFStringCreateWithSubstring(kCFAllocatorDefault, string, CFRangeMake(caretPosition, 1));
	CFAttributedStringRef attributedString = CFAttributedStringCreate(kCFAllocatorDefault,character,NULL);
	return CTLineCreateWithAttributedString(attributedString);
}

/*
 If the line is not complete, increments the caret position, then...
 Returns a CTLineRef containing the current character
 */
-(CTLineRef)nextCharacterAsLineRef {
	if ([self complete] == kCFBooleanFalse) {
		caretPosition++;
		if(caretPosition == totalCharacters) complete = kCFBooleanTrue;
	}
	return [self currCharacterAsLineRef];
}

/*
 Returns a CFStringRef containing the current character
 */
-(CFStringRef)currCharacterAsCFStringRef {
	if (caretPosition == -1) caretPosition++;
	if(beingUsed == kCFBooleanFalse) beingUsed = kCFBooleanTrue;
	CFStringRef character = CFStringCreateWithSubstring(kCFAllocatorDefault, string, CFRangeMake(caretPosition, 1));
	return character;
}

/*
 If the line is not complete, increments the caret position, then...
 Returns a CFStringRef containing the current character
 */
-(CFStringRef)nextCharacterAsCFStringRef {
	if ([self complete] == kCFBooleanFalse) {
		caretPosition++;
		if(caretPosition == totalCharacters-1) complete = kCFBooleanTrue;
	}
	return [self currCharacterAsCFStringRef];
}

-(void)reset {
	caretPosition = -1;
	beingUsed = kCFBooleanFalse;
	complete = kCFBooleanFalse;
}

#pragma mark print functions
-(void)printNextCharacter {
	//printf("[TIString printNextCharacter]");
	[self printCFStringRef:[self nextCharacterAsCFStringRef]];
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

-(void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:(NSString*)string forKey:@"string"];
	[coder encodeInt:(int)totalCharacters forKey:@"totalCharacters"];
	[coder encodeInt:(int)caretPosition forKey:@"caretPosition"];
	[coder encodeBool:CFBooleanGetValue(beingUsed) forKey:@"beingUsed"];
	[coder encodeBool:CFBooleanGetValue(complete) forKey:@"complete"];
}

-(id)initWithEncoder:(NSCoder *)decoder {
	if(![self init]) return nil;
	string = CFStringCreateCopy(kCFAllocatorDefault, (CFStringRef)[decoder decodeObjectForKey:@"string"]);
	totalCharacters = (CFIndex)[decoder decodeObjectForKey:@"totalCharacters"];
	caretPosition = (CFIndex)[decoder decodeIntForKey:@"caretPosition"];
	Boolean b = [decoder decodeBoolForKey:@"beingUsed"];
	if (b == true) beingUsed = kCFBooleanTrue;
	else beingUsed = kCFBooleanFalse;
	b = [decoder decodeBoolForKey:@"complete"];
	if(b == true) complete = kCFBooleanTrue;
	else complete = kCFBooleanFalse;
	return self;
}

@end
