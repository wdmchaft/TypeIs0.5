//
//  TIString.h
//  TypeIs0.5
//
//  Created by collab-macpro on 10-03-08.
//  Copyright 2010 Travis Kirton. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*
 NOTE:	Contains necessary methods for retrieving text, char by char
		Has flag for being used (limits 2 cursors from drawing the same paragraph)
		Has flag for complete, will be possible to reset this at an appropriate time
 */

@interface TIString : NSObject {
@private
	//Text
	CFStringRef  string;
	
	//Numbers
	CFIndex				totalCharacters;	//So we don't have to query the string itself
	CFIndex				caretPosition;		//Keeps track of the position in the string

	//Booleans
	CFBooleanRef		beingUsed;
	CFBooleanRef		complete;
}

-(id)initWithCFStringRef:(CFStringRef)stringRef;
-(id)initWithNSString:(NSString *)nsstring;

#pragma mark accessor functions
-(CFIndex)totalCharacters;
-(CFIndex)caretPosition;

-(CFBooleanRef)beingUsed;
-(CFBooleanRef)complete;
-(void)setBeingUsed:(CFBooleanRef)aBool;

-(CFStringRef)completeString;
-(CFStringRef)usedString;
-(CFStringRef)remainingString;

-(CTLineRef)currCharacterAsLineRef;
-(CTLineRef)nextCharacterAsLineRef;
-(CFStringRef)currCharacterAsCFStringRef;
-(CFStringRef)nextCharacterAsCFStringRef;

//-(CGPathRef)convertPathToViewCoordinates:(CGPathRef)aPath;

-(void)reset;

#pragma mark print functions
-(void)printNextCharacter;
@end
