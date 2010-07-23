//
//  TILineManager.h
//  TypeIs0.5
//
//  Created by collab-macpro on 10-03-09.
//  Copyright 2010 Travis Kirton. All rights reserved.
//

#import	 <Cocoa/Cocoa.h>
#include "TICursorLine.h"
#include "TIPoint.h"
#include "TITextStorage.h"
#include "TICharacter.h"

#ifdef TUIO 
#include "TuioClient.h"
#endif

/*
 NOTE:	This class should manage input from a device (e.g. camera, pen, mouse)
		It will create serializable point arrays (lines) base on event data
		It will read text data and retrieve characters appropriately
		It will interpret lines, and calculate glyph sizes
		It will pass glyph data back to a renderer
 */

@interface TILineManager : NSObject {
	NSFont	*currentFont;
	NSColor *currentColor;
	CGFloat zoomFactor;
	
	TITextStorage	*myTextStorage;
	TICursorLine	*mouseCursorLine;

	NSMutableArray	*linesBeingDrawn;	//array of lines currently being drawn, a line should drop if a tuiocursor is dropped
	NSMutableArray	*completedLines;	//stores for future reference, serializable?
	NSMutableArray	*bufferedLines;		//stores a buffered set of cursorLines
	NSMutableArray  *bufferedCharacters;
	
	CFTimeInterval	startTime;
	CFBooleanRef	firstPointRecorded;

	CFIndex			lineCountForMouseInteraction;
}

@property (readwrite,retain) NSFont  *currentFont;
@property (readwrite,retain) NSColor  *currentColor;
@property (readwrite) CGFloat zoomFactor;

-(id)_init;
+(TILineManager *)sharedManager;

-(void)addPoint:(CGPoint)point toLineForID:(NSUInteger)uniqueID andTimeStamp:(CFTimeInterval)timeStamp;
-(void)addLineWithPoint:(CGPoint)point withID:(NSUInteger)uniqueID andTimeStamp:(CFTimeInterval)timeStamp;

#ifdef TUIO
-(void)processTuioCursorEvent:(NSEvent *)theEvent;
-(CFBooleanRef)tuioCursorExists:(NSUInteger)uniqueID;
-(CFBooleanRef)lineIdExists:(CFIndex)uniqueID inTuioDictionary:(NSMutableDictionary *)theDictionary;
#endif

-(void)processEvent:(NSEvent *)theEvent;
#ifdef TUIO
-(void)processTuioDictionary:(NSMutableDictionary *)tuioCursorDictionary;
#endif

-(TICharacter *)getNextCharacter;
-(NSArray *)getBufferedCharacters;
-(NSArray *)getPointArray;
-(NSArray *)getCompletedLines;
-(NSArray *)getAllCharacters;
-(TICursorLine *)getLastLine;
@end