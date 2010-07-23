//
//  TICursorLine.h
//  TypeIs0.5
//
//  Created by collab-macpro on 10-03-09.
//  Copyright 2010 Travis Kirton. All rights reserved.
//
#define ktiMinDistanceForNewPoint 0.20f

#import <Cocoa/Cocoa.h>
#import "TIPoint.h"
#import "TIString.h"
#import "TICharacter.h"
/*
 NOTE:	This class will create a point array (line) from event data
		Event data is essentially a cursor (i.e. not a mouse cursor)
		This will provide a basis on top of which glyph data will be generated
		A line will grow throughout the duration of a single cursor (e.g. on screen)
 */

@interface TICursorLine : NSObject {
	TIPoint			*currentPoint, *currentOrigin;
	NSColor			*currentColor;
	NSFont			*currentFont;
	
	CFIndex			uniqueID;
	CFTimeInterval	startTime;
	CFBooleanRef	nextCharIsAvailable;
	CFBooleanRef	charactersAvailable;
	NSMutableArray	*pointArray;
	TIString		*string;
	
	NSString		*currentCharacter;
	NSMutableArray	*availableCharacters;

	CGFloat			currentCharacterWidth;
	CGFloat			totalDistance;
	CGFloat			distanceToEndOfLastChar;
	CGFloat			distanceToEndOfPrevChar;
}

-(id)initWithPoint:(CGPoint)point uniqueID:(CFIndex)idAsIndex andTimeStamp:(CFTimeInterval)timeStamp andTIString:(TIString *)tiString andFont:(NSFont *)font andColor:(NSColor *)color;
-(id)initWithPoint:(CGPoint)point uniqueID:(CFIndex)idAsIndex andTimeStamp:(CFTimeInterval)timeStamp andTIString:(TIString *)tiString andFont:(NSFont *)font;
-(id)initWithPoint:(CGPoint)point uniqueID:(CFIndex)idAsIndex andTimeStamp:(CFTimeInterval)timeStamp andTIString:(TIString *)tiString;
-(id)initWithPoint:(CGPoint)point uniqueID:(CFIndex)idAsIndex andTimeStamp:(CFTimeInterval)timeStamp;
-(void)resetWithNewString:(TIString *)tiString;
-(void)addPoint:(CGPoint)point withTimeStamp:(CFTimeInterval)timeStamp;
-(CFIndex)uniqueID;
-(void)finishedBeingUsed;
-(CFBooleanRef)needsNewString;
-(CFIndex)length;
-(CFStringRef)getNextCharacter;
-(NSArray *)getCharacters;
-(CFBooleanRef)nextCharIsAvailable;
-(CGFloat)calculateCurrentCharacterWidth:(NSString *)aChar;
-(CGFloat)angleForCurrentCharacter;
-(NSValue *)positionForCurrentCharacter;

-(void)checkDisplacement;

/* from textdraw */

-(NSNumber *)alphaAtDistance:(NSNumber *)number;
-(NSNumber *)angleAtDistance:(NSNumber *)number;
-(NSNumber *)pointSizeAtDistance:(NSNumber *)number;
-(NSValue  *)positionAtDistance:(NSNumber *)number;

-(NSUInteger)previousIndexForDistance:(NSNumber *)number;
-(TIPoint *)tiPointAtIndex:(NSUInteger)index;

-(NSArray *)getPointArray;

@property(readwrite,retain) TIPoint	*currentPoint;
@property(readwrite,retain) TIPoint *currentOrigin;
@property(readwrite,retain) NSColor *currentColor;
@property(readwrite,retain) NSFont	*currentFont;

@end