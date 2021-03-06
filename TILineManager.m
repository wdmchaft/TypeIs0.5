//
//  TILineManager.m
//  TypeIs0.5
//
//  Created by collab-macpro on 10-03-09.
//  Copyright 2010 Travis Kirton. All rights reserved.
//

#import "TILineManager.h"

static TILineManager *myTILineManager;

@implementation TILineManager

GENERATE_SINGLETON(TILineManager, myTILineManager);

@synthesize currentFont, currentColor, zoomFactor;

-(id)_init {
	myTextStorage = [TITextStorage sharedManager];
	linesBeingDrawn = [[[NSMutableArray alloc] init] retain];
	completedLines = [[[NSMutableArray alloc] init] retain];
	bufferedCharacters = [[[NSMutableArray alloc] init] retain];
	firstPointRecorded = kCFBooleanFalse;
	lineCountForMouseInteraction = 0;
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(changeFont:)
												 name:@"ControllerDidChangeFont"
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(changeColor:)
												 name:@"ControllerDidChangeColor"
											   object:nil];
	return self;
}

-(void)initWithLineManager:(TILineManager *)lineManager {
	[self setCurrentFont:[lineManager currentFont]];
	[self setCurrentColor:[lineManager currentColor]];
	[self setZoomFactor:[lineManager zoomFactor]];
	if (completedLines != nil) {
		[completedLines release];
		completedLines = nil;
	}
	completedLines = [lineManager->completedLines copy];
	lineCountForMouseInteraction = [lineManager lineCountForMouseInteraction];
	[myTextStorage initWithTextStorage:lineManager->myTextStorage];
	linesBeingDrawn = [lineManager->linesBeingDrawn copy];
	bufferedCharacters = [lineManager->bufferedCharacters copy];
	if([completedLines count] > 0) firstPointRecorded = kCFBooleanTrue;
	else firstPointRecorded = kCFBooleanFalse;
}

-(void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:currentFont forKey:@"currentFont"];
	[coder encodeObject:currentColor forKey:@"currentColor"];
	[coder encodeFloat:(float)zoomFactor forKey:@"zoomFactor"];
	[coder encodeInt:[completedLines count] forKey:@"completedLinesCount"];
	for(int i = 0; i < [completedLines count]; i++){
		[coder encodeObject:[completedLines objectAtIndex:i]];
	} 
	[coder encodeInt:(int)lineCountForMouseInteraction forKey:@"lineCountForMouseInteraction"];
	[coder encodeObject:myTextStorage forKey:@"myTextStorage"];
}

-(id)initWithCoder:(NSCoder *)decoder {
	if(![super init]) return nil;
	[self setCurrentFont:[decoder decodeObjectForKey:@"currentFont"]];
	[self setCurrentColor:[decoder decodeObjectForKey:@"currentColor"]];
	[self setZoomFactor:(CGFloat)[decoder decodeFloatForKey:@"zoomFactor"]];
	int completedLinesCount = [decoder decodeIntForKey:@"completedLinesCount"];
	completedLines = [[[NSMutableArray alloc] init] retain];
	for(int i = 0; i < completedLinesCount; i++) [completedLines addObject:(TICursorLine*)[decoder decodeObject]];
	lineCountForMouseInteraction = [decoder decodeIntForKey:@"lineCountForMouseInteraction"];
	[myTextStorage initWithTextStorage:[decoder decodeObjectForKey:@"myTextStorage"]];
	
	linesBeingDrawn = [[[NSMutableArray alloc] init] retain];
	bufferedCharacters = [[[NSMutableArray alloc] init] retain];
	firstPointRecorded = kCFBooleanFalse;
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(changeFont:)
												 name:@"ControllerDidChangeFont"
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(changeColor:)
												 name:@"ControllerDidChangeColor"
											   object:nil];
	return self;
}

#ifdef TUIO
-(void)processTuioDictionary:(NSMutableDictionary *)tuioCursorDictionary {
	NSMutableDictionary *tuioDictionary = [[[NSMutableDictionary alloc] initWithDictionary:tuioCursorDictionary] autorelease];
	
	//Checks all line ids against cursor dictionary, removes them from 
	for(TICursorLine *line in linesBeingDrawn){
		if([self lineIdExists:[line uniqueID] inTuioDictionary:tuioDictionary] == kCFBooleanFalse){
			[line finishedBeingUsed];
			[completedLines addObject:line];
			[linesBeingDrawn removeObject:line];
		}
	}
	
	NSEnumerator *tuioDictionaryEnumerator = [tuioDictionary keyEnumerator];
	id dictionaryObjectKey;
	while(dictionaryObjectKey = [tuioDictionaryEnumerator nextObject]){
		TuioCursor *tuioCursor = [tuioDictionary objectForKey:dictionaryObjectKey];
		
		NSEvent *tuioEvent = [NSEvent otherEventWithType:NSApplicationDefined
												location:[tuioCursor position]
										   modifierFlags:ktiTUIOCursorEvent
											   timestamp:CFAbsoluteTimeGetCurrent()
											windowNumber:0
												 context:0
												 subtype:0
												   data1:[tuioCursor uniqueID]
												   data2:0];
		[self processEvent:tuioEvent];
	}
}
#endif
-(void)changeFont:(id)sender{
	[self setCurrentFont:[[sender userInfo] valueForKey:@"font"]];
}
-(void)changeColor:(id)sender{
	[self setCurrentColor:[[sender userInfo] objectForKey:@"color"]];
}

-(void)processEvent:(NSEvent *)theEvent {

	if (firstPointRecorded == kCFBooleanFalse) {
		startTime = CFAbsoluteTimeGetCurrent();
		firstPointRecorded = kCFBooleanTrue;
	}
	switch ([theEvent type]) {
		case NSLeftMouseDown:
			if([myTextStorage hasContent] == kCFBooleanTrue){
				
				if(mouseCursorLine != nil){
					[mouseCursorLine release];
				}
				mouseCursorLine = [[[TICursorLine alloc] initWithPoint:NSPointToCGPoint([theEvent locationInWindow])
															  uniqueID:lineCountForMouseInteraction 
														  andTimeStamp:CFAbsoluteTimeGetCurrent() 
														   andTIString:[myTextStorage nextAvailableParagraph]
															   andFont:[self currentFont]
															  andColor:[self currentColor]] retain];
			} else {
				printf("choose a text\n");
			}
			break;
		case NSLeftMouseDragged:
			if([myTextStorage hasContent] == kCFBooleanTrue){
				[mouseCursorLine addPoint:NSPointToCGPoint([theEvent locationInWindow]) withTimeStamp:CFAbsoluteTimeGetCurrent()];
				if ([mouseCursorLine needsNewString] == kCFBooleanTrue) {
					[mouseCursorLine resetWithNewString:[myTextStorage nextAvailableParagraph]];
				}
			}
			break;
		case NSLeftMouseUp:
			if([myTextStorage hasContent] == kCFBooleanTrue){
				[mouseCursorLine finishedBeingUsed];
				[completedLines addObject:mouseCursorLine];
				[mouseCursorLine release];
				mouseCursorLine = nil;
				[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"MouseCursorLineCompleted" object:nil]];
			}
			lineCountForMouseInteraction++;
			break;
		case NSApplicationDefined:
#ifdef TUIO
			if ([theEvent modifierFlags] == ktiTUIOCursorEvent) {
				[self processTuioCursorEvent:theEvent];
			}
#endif
			break;
		default:
			printf("\n this isn't right ");
			break;
	}
}

#ifdef TUIO
-(void)processTuioCursorEvent:(NSEvent *)theEvent {
	if([myTextStorage hasContent] == kCFBooleanTrue){
		if ([self tuioCursorExists:[theEvent data1]] == kCFBooleanTrue) {
			//printf("\n    add point ");
			[self addPoint:NSPointToCGPoint([theEvent locationInWindow]) toLineForID:[theEvent data1] andTimeStamp:[theEvent timestamp]];
		} else {
			//printf("\nadd line ");
			[self addLineWithPoint:NSPointToCGPoint([theEvent locationInWindow]) withID:[theEvent data1] andTimeStamp:[theEvent timestamp]];
		}
	} else {
		printf("choose a text\n");
	}
}

-(CFBooleanRef)lineIdExists:(CFIndex)uniqueID inTuioDictionary:(NSMutableDictionary *)tuioDictionary {
	NSEnumerator *tuioDictionaryEnumerator = [tuioDictionary keyEnumerator];
	id dictionaryObjectKey;
	while(dictionaryObjectKey = [tuioDictionaryEnumerator nextObject]){
		TuioCursor *tuioCursor = [tuioDictionary objectForKey:dictionaryObjectKey];
		if (uniqueID == (int)[tuioCursor uniqueID]) {
			return kCFBooleanTrue;
		}
	}
	return kCFBooleanFalse;
}
#endif

-(CFBooleanRef)tuioCursorExists:(NSUInteger)uniqueID {
	CFIndex idAsIndex = (int)uniqueID;
	for(TICursorLine *line in linesBeingDrawn){
		if (idAsIndex == [line uniqueID]) {
			return kCFBooleanTrue;
		}
	}
	return kCFBooleanFalse;
}

-(void)addLineWithPoint:(CGPoint)point withID:(NSUInteger)uniqueID andTimeStamp:(CFTimeInterval)timeStamp {
	CFIndex idAsIndex = (int)uniqueID;
	timeStamp -= startTime;
	if (timeStamp < 0) timeStamp = 0;
	TICursorLine *line = [[[TICursorLine alloc] initWithPoint:point uniqueID:idAsIndex andTimeStamp:timeStamp andTIString:[myTextStorage nextAvailableParagraph] andFont:currentFont] autorelease];
	[linesBeingDrawn addObject:line];
}

-(void)addPoint:(CGPoint)point toLineForID:(NSUInteger)uniqueID andTimeStamp:(CFTimeInterval)timeStamp {
	//printf("\n    point(%4.2f,%4.2f)",point.x,point.y);
	CFIndex idAsIndex = (CFIndex)uniqueID;
	for(TICursorLine *line in linesBeingDrawn){
		if(idAsIndex == [line uniqueID]){
			timeStamp -= startTime;
			if (timeStamp < 0) timeStamp = 0;
			[line addPoint:point withTimeStamp:timeStamp];
			if ([line needsNewString] == kCFBooleanTrue) {
				[line resetWithNewString:[myTextStorage nextAvailableParagraph]];
			}
		}
	}
}

-(NSArray *)getBufferedCharacters {
	NSArray *temp = [mouseCursorLine getCharacters];
	[bufferedCharacters addObjectsFromArray:temp];
	return temp;
}

-(TICharacter *)getNextCharacter {
	return nil;
}

-(NSArray *)getPointArray {
	NSArray *arr = [mouseCursorLine getPointArray];
	return arr;
}

-(NSArray *)getAllCharacters {
	return [bufferedCharacters copy];
}

-(NSArray *)getCompletedLines {
	return [completedLines copy];
}

-(TICursorLine *)getLastLine {
	return [completedLines lastObject];
}

-(int)lineCountForMouseInteraction {
	return lineCountForMouseInteraction;
}
@end
