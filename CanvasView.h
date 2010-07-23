//
//  CanvasView.h
//  TypeIs0.5
//
//  Created by collab-macpro on 10-06-29.
//  Copyright 2010 Travis Kirton. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ScrollViewWorkaround.h"

#import "TIPoint.h"
#import "TICharacter.h"

@class TIDocument;

@interface CanvasView : NSOpenGLView {
	CGFloat	zoomFactor;
	NSColor	*currentColor;
	
	IBOutlet TIDocument	* document;
	CGRect			imageRect;
	NSArray			*currentLine;
	NSMutableArray	*currentCharacters;
	BOOL			readyToDraw;
}

-(void)drawCurrentLine;
-(void)drawCurrentCharacters;
-(void)setCurrentLineToBeDrawn:(NSArray *)pointArray;
-(void)setCharactersToBeDrawn:(NSArray *)characterArray;
-(NSArray*)getCurrentCharacters;
-(NSBezierPath *)currentPath;
-(void)changeColor:(id)sender;

@property(readwrite) CGFloat zoomFactor;
@property(readwrite,retain) NSColor *currentColor;
@end