//
//  TICursorLine.m
//  TypeIs0.5
//
//  Created by collab-macpro on 10-03-09.
//  Copyright 2010 Travis Kirton. All rights reserved.
//

#import "TICursorLine.h"

@interface TICursorLine (private)
-(void)createAndAddTIPoint:(CGPoint)point withTimeStamp:(CFTimeInterval)timeStamp;
-(void)printNextCharacter;
@end

@implementation TICursorLine
@synthesize currentPoint;
@synthesize currentOrigin;
@synthesize currentColor;
@synthesize currentFont;
@synthesize finished;

/* note: rethink the way i cascade these init calls */

-(id)initWithPoint:(CGPoint)point uniqueID:(CFIndex)idAsIndex andTimeStamp:(CFTimeInterval)timeStamp andTIString:(TIString *)tiString andFont:(NSFont *)font andColor:(NSColor *)color{
	[self setCurrentColor:color];
	return [self initWithPoint:point uniqueID:idAsIndex andTimeStamp:timeStamp andTIString:tiString andFont:font];
}

-(id)initWithPoint:(CGPoint)point uniqueID:(CFIndex)idAsIndex andTimeStamp:(CFTimeInterval)timeStamp andTIString:(TIString *)tiString andFont:(NSFont *)font {
	string = [[TIString alloc] init];
	string = tiString;
	[string setBeingUsed:kCFBooleanTrue];
	[self setCurrentFont:font];
	currentCharacter = (NSString *)[string currCharacterAsCFStringRef];
	currentCharacterWidth = 0.0f;
	totalDistance = 0.0f;
	distanceToEndOfPrevChar = 0.0f;
	
	return [self initWithPoint:point uniqueID:idAsIndex andTimeStamp:timeStamp];
}

-(id)initWithPoint:(CGPoint)point uniqueID:(CFIndex)idAsIndex andTimeStamp:(CFTimeInterval)timeStamp andTIString:(TIString *)tiString {
	string = [[TIString alloc] init];
	string = tiString;
	[string setBeingUsed:kCFBooleanTrue];
	
	totalDistance = 0.0f;
	distanceToEndOfPrevChar = 0.0f;

	return [self initWithPoint:point uniqueID:idAsIndex andTimeStamp:timeStamp];
}

-(id)initWithPoint:(CGPoint)point uniqueID:(CFIndex)idAsIndex andTimeStamp:(CFTimeInterval)timeStamp {
	if (![super init]) {
		return nil;
	}

	if ([self currentColor] == nil) {
		printf("color is nil");
		[self setCurrentColor:[NSColor blackColor]];
	}
	
	uniqueID = idAsIndex;
	pointArray = [[[NSMutableArray alloc] init] retain];
	availableCharacters = [[[NSMutableArray alloc] init] retain];
	startTime = timeStamp;
	
	currentCharacterWidth = [self calculateCurrentCharacterWidth:currentCharacter];
		
	TIPoint *p = [[[TIPoint alloc] initWithOrigin:point andTimeStamp:timeStamp] autorelease];
	[p setDistance:0.0f];
	
	[self setCurrentOrigin:[TIPoint pointWithPoint:p]];
	[self setCurrentPoint:p];
	
	[pointArray addObject:[self currentPoint]];
	nextCharIsAvailable = kCFBooleanTrue;
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(checkDisplacement)
												 name:@"TICursorDidPostAvailableCharacters"
											   object:self];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(postAvailableCharacters)
												 name:@"TICursorLineDidAddPoint"
											   object:self];
	[self setFinished:NO];
	return self;
}

-(void)dealloc {
	[currentPoint release];
	[currentOrigin release];
	[currentColor release];
	[currentFont release];
	[pointArray removeAllObjects];
	[pointArray release];
	[string release];
	[currentCharacter release];
	[availableCharacters removeAllObjects];
	[availableCharacters release];
	[super dealloc];
}

-(void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:(int)uniqueID forKey:@"uniqueID"];
	[coder encodeDouble:(double)startTime forKey:@"startTime"];
	[coder encodeInt:[pointArray count] forKey:@"pointArrayCount"];
	for(int i = 0; i < [pointArray count]; i++){
		[coder encodeObject:[pointArray objectAtIndex:i]];
	}
	[coder encodeObject:string forKey:@"string"];
}

-(id)initWithCoder:(NSCoder *)decoder {
	if(![super init]) return nil;
	uniqueID = [decoder decodeIntForKey:@"uniqueID"];
	startTime = (CFTimeInterval)[decoder decodeDoubleForKey:@"startTime"];
	int pointArrayCount = [decoder decodeIntForKey:@"pointArrayCount"];
	pointArray = [[[NSMutableArray alloc] init] retain];
	for(int i = 0; i < pointArrayCount; i++) (TIPoint *)[decoder decodeObject];
	string = [[TIString alloc] init];
	string = [decoder decodeObjectForKey:@"string"];
	[self setFinished:YES];
	return self;
}

-(void)resetWithNewString:(TIString *)tiString {
	string = tiString;
}

-(void)addPoint:(CGPoint)point withTimeStamp:(CFTimeInterval)timeStamp {
	if([[pointArray lastObject] distanceToPoint:point] >= ktiMinDistanceForNewPoint && [self finished] == NO){
		//printf("addPoint\n");
		TIPoint *p = [[[TIPoint alloc] initWithOrigin:point andTimeStamp:timeStamp] autorelease];
		if (p != nil) {
			[pointArray addObject:p];
			[self setCurrentPoint:p];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"TICursorLineDidAddPoint" object:self];
		}
	}
}

-(void)checkDisplacement {
	CGFloat displacement = [[self currentOrigin] distanceToTIPoint:[self currentPoint]];
	//printf("dispacement:%4.2f ",displacement);
	if (displacement >= currentCharacterWidth) {
		//printf("here");
		[self setCurrentOrigin:[TIPoint pointWithPoint:[self currentPoint]]];
		//printf("origin changed\n\n");
		[[NSNotificationCenter defaultCenter] postNotificationName:@"TICursorLineOriginDidChange" object:self];
	}
}

-(NSString *)description {
	NSMutableString *descriptionString = [[[NSMutableString alloc] init] autorelease];
	[descriptionString appendString:[NSString stringWithFormat:@"lineID[%d]\n",uniqueID]];
	for(TIPoint *point in pointArray){
		[descriptionString appendString:[NSString stringWithFormat:@"   (%4.2f,%4.2f {%4.2f,%4.2f})\n",[point origin].x,[point origin].y,[point angle],[point distance]]];
	}
	[descriptionString appendString:@"\n"];
	return (NSString *)descriptionString;
}

-(CFIndex)uniqueID {
	return uniqueID;
}

-(void)finishedBeingUsed {
	[string setBeingUsed:kCFBooleanFalse];
	[self setFinished:YES];
}

-(CFIndex)length {
	return [pointArray count];
}

-(CFBooleanRef)needsNewString {
	return [string complete];
}

-(CFBooleanRef)nextCharIsAvailable {
	return nextCharIsAvailable;
}

-(CFStringRef)getNextCharacter {
	currentCharacter = (NSString *)[string nextCharacterAsCFStringRef];
	//printf("currentCharacter:'%s' ",[currentCharacter UTF8String]);
	currentCharacterWidth = [self calculateCurrentCharacterWidth:currentCharacter];
	//printf("currentCharacterWidth:%4.2f\n",currentCharacterWidth);
	distanceToEndOfPrevChar += currentCharacterWidth;
	return (CFStringRef)currentCharacter;
}

-(NSArray *)getCharacters {
	if([pointArray count] > 1 && [availableCharacters count] > 0){
		NSArray *temp = [NSArray arrayWithArray:availableCharacters];
		[availableCharacters removeAllObjects];
		return temp;
	} 
	return nil;
}

-(void)postAvailableCharacters {
	CGFloat displacementToCurrentPoint = [[self currentOrigin] distanceToTIPoint:[self currentPoint]];
	while (displacementToCurrentPoint > currentCharacterWidth) {
		displacementToCurrentPoint = [[self currentOrigin] distanceToTIPoint:[self currentPoint]];
		if (displacementToCurrentPoint <= 0.0f) break;
		NSFont		*tempFont = [self currentFont];
		NSColor		*tempColor = [self currentColor];
		NSArray *keys = [NSArray arrayWithObjects:NSFontAttributeName,NSForegroundColorAttributeName,nil];
		NSArray *objects = [NSArray arrayWithObjects:tempFont,tempColor,nil];
		NSDictionary *attributes = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
		TICharacter *newChar = [[[TICharacter alloc] initWithAngle:[NSNumber numberWithFloat:[[self currentOrigin] angle]] 
														attributes:attributes
														 character:currentCharacter
												  andPositionValue:[NSValue valueWithPoint:NSPointFromCGPoint([[self currentOrigin] origin])]] autorelease];
	
		
		/* something wrong in the rotation here */
		//-
			CGPoint p0 = [[self currentOrigin] origin];
			CGPoint p1 = [[self currentPoint] origin];

			p1.x -= p0.x;
			p1.y -= p0.y;
			CGFloat theta = 0.0f;
			CGFloat r = 0.0f;
			CGFloat x = 0.0f;
			CGFloat y = 0.0f;

			theta = atan(p1.y/p1.x);
			if(p1.x < 0) theta -= pi;
			r = currentCharacterWidth;
			x = r*cos(theta);
			y = r*sin(theta);
			
			if(p1.x < 0){
				x *= -1;
				y *= -1;
			}

			x += p0.x;
			y += p0.y;			
			//CGPoint newLocation = CGPointMake(x, y);

			[self checkDisplacement];
			//printf("\ncurrentOriginAngle:%4.2f -> ",[[self currentOrigin] angle]);
			[[self currentOrigin] setAngle:theta];
			//printf("%4.2f\n",[[self currentOrigin] angle]);
			[newChar setAngle:[NSNumber numberWithFloat:theta]];
		
			if (newChar != nil) {
				[availableCharacters addObject:newChar];
				totalDistance += currentCharacterWidth;
				currentCharacterWidth = 0;
				//printf("totalDistance:%4.2f v. ",totalDistance);
				//printf("displacement:%4.2f ",displacementToCurrentPoint);
				//printf("currentCharacterWidth:%4.2f\n",currentCharacterWidth);
				[self getNextCharacter];
			}
	} 
		
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"TICursorDidPostAvailableCharacters" object:self]];
	charactersAvailable = kCFBooleanTrue;
}

-(CGFloat)calculateCurrentCharacterWidth:(NSString *)aChar {
	NSFont *tempFont = [self currentFont];
	NSDictionary *fontAttributes = [NSDictionary dictionaryWithObject:tempFont forKey:NSFontAttributeName];
	NSAttributedString *attributedChar = [[[NSAttributedString alloc] initWithString:(NSString *)aChar attributes:fontAttributes] autorelease];

	NSSize glyphSize	=	[aChar sizeWithAttributes:fontAttributes]; 
	NSRect glyphBounds	=	[attributedChar boundingRectWithSize:glyphSize options:NSStringDrawingUsesLineFragmentOrigin];

	CGFloat width = fabs(glyphBounds.size.width);	
	return width;
}

-(CGFloat)angleForCurrentCharacter {
	if ([pointArray count] > 1) {
		return [[self angleAtDistance:[NSNumber numberWithFloat:distanceToEndOfPrevChar]] floatValue];
	}
	return 0.0f;
}

-(NSValue *)positionForCurrentCharacter {
	if (distanceToEndOfPrevChar == 0.0f) {
		return [NSValue valueWithPoint:NSPointFromCGPoint([[pointArray objectAtIndex:0] origin])];
	}
	return [self positionAtDistance:[NSNumber numberWithFloat:distanceToEndOfPrevChar]];
}

-(NSArray *)getPointArray {
	NSArray *arr = [[NSArray alloc] init];
	arr = [pointArray copy];
	return arr;
}

#pragma mark from textdraw

-(NSNumber *)alphaAtDistance:(NSNumber *)number {
	return [NSNumber numberWithFloat:1.0f];
}

-(NSNumber *)angleAtDistance:(NSNumber *)number {
	return [NSNumber numberWithFloat:[[pointArray objectAtIndex:[self previousIndexForDistance:number]] angle]];
}

-(NSNumber *)pointSizeAtDistance:(NSNumber *)number {
	return [NSNumber numberWithFloat:0.0f];
}

-(NSValue  *)positionAtDistance:(NSNumber *)number {
	CGFloat distance = [number floatValue];
	
	NSUInteger index0 = [self previousIndexForDistance:number]; //added -1 here... don't know why...
	
	NSUInteger index1 = index0+1;
	if ([pointArray count] == 1){
		return [NSValue valueWithPoint:NSPointFromCGPoint([[pointArray objectAtIndex:index0] origin])];
	}
	else if ([pointArray count] >= 2){
		if(index0 < [pointArray count]-1) {
			NSPoint p0 = NSPointFromCGPoint([[pointArray objectAtIndex:index0] origin]);
			NSPoint p1 = NSPointFromCGPoint([[pointArray objectAtIndex:index1] origin]);
			p1.x -= p0.x;
			p1.y -= p0.y;
			CGFloat theta = 0.0f;
			CGFloat r = 0.0f;
			CGFloat x = 0.0f;
			CGFloat y = 0.0f;
			
			theta = atan(p1.y/p1.x);
			r = distance - [[pointArray objectAtIndex:index1] distance];
			x = r*cos(theta);
			y = r*sin(theta);
			
			if(p1.x < 0){
				x *= -1;
				y *= -1;
			}
			
			x += p0.x;
			y += p0.y;
			
			return [NSValue valueWithPoint:NSMakePoint(x, y)];
		}
	}
	return [NSValue valueWithPoint:NSMakePoint(-100.0f, -100.0f)];
}

-(NSUInteger)previousIndexForDistance:(NSNumber *)number
{
	CGFloat distance = [number floatValue];
	NSUInteger idx = [pointArray count]-1;
	if(idx <= 0) idx = 0;
	else {
		//start from the end of a line
		//printf("dToEndOfLine:%4.2f dpc:%4.2f\n",[[pointArray objectAtIndex:idx] distance],distance);
		while ([[pointArray objectAtIndex:idx] distance] >= distance) {
			idx--;
			if (idx == 0) break;
		}
	}
	return idx;
}

-(TIPoint *)tiPointAtIndex:(NSUInteger)index {
	return nil;
}


#pragma mark print functions
-(void)printNextCharacter {
	[string printNextCharacter];
}
@end
