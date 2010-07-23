//
//  CanvasView.m
//  TypeIs0.5
//
//  Created by collab-macpro on 10-06-29.
//  Copyright 2010 Travis Kirton. All rights reserved.
//

#import "CanvasView.h"
#import "TIDocument.h"

@implementation CanvasView 
@synthesize zoomFactor,currentColor;

-(id)initWithFrame:(NSRect)frameRect {
	NSOpenGLPixelFormatAttribute attrs[] = 
    {
        NSOpenGLPFAWindow,
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFAColorSize, 24,
        NSOpenGLPFAAlphaSize, 8, 
        NSOpenGLPFADepthSize, 24,
        NSOpenGLPFASampleBuffers, 2,
        NSOpenGLPFASamples, 2,
        NSOpenGLPFAAccumSize, 32,
        NSOpenGLPFANoRecovery,
        NSOpenGLPFAAccelerated,
        0
    };

	
	
	NSOpenGLPixelFormat* fmt = [[NSOpenGLPixelFormat alloc] initWithAttributes: (NSOpenGLPixelFormatAttribute*) attrs]; 
    self = [super initWithFrame:frameRect pixelFormat: [fmt autorelease]];	
	return self;
}

-(NSArray *)getCurrentCharacters {
	NSArray *currentCharactersCopy = [currentCharacters copy];
	[currentCharacters removeAllObjects];
	[self setNeedsDisplay:YES];
	return currentCharactersCopy;
}

-(void)awakeFromNib {
	[self setCurrentColor:[NSColor blackColor]];
	readyToDraw = NO;
	currentLine = [NSArray array];
	currentCharacters = [[[NSMutableArray alloc] initWithCapacity:0] retain];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(render)
												 name:@"CanvasViewNeedsDisplay"
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(changeColor:)
												 name:@"ControllerDidChangeColor"
											   object:nil];
}

-(void)changeColor:(id)sender {
	[self setCurrentColor:[[sender userInfo] valueForKey:@"color"]];
}

-(void)keyDown:(NSEvent *)theEvent {
	[document keyDown:theEvent];
}

-(void)prepareOpenGL {
    [[self window] setOpaque:NO];
	glClearColor(0, 0, 0, 0);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glEnable(GL_LINE_SMOOTH);
	glEnable(GL_BLEND);
	glDisable(GL_DITHER);
	glDisable(GL_STENCIL_TEST);
	glDisable(GL_FOG);
	glDisable(GL_TEXTURE_2D);
	glDisable(GL_DEPTH_TEST);
	glPixelZoom(1.0, 1.0);
	glHint(GL_LINE_SMOOTH_HINT, GL_NICEST);
	GLint swapInterval = 1;
	[[self openGLContext] setValues:&swapInterval forParameter:NSOpenGLCPSwapInterval];	
	GLint opacity = 0;
	[[self openGLContext] setValues:&opacity forParameter:NSOpenGLCPSurfaceOpacity];	
	
	readyToDraw = YES;
}

-(void)render {
	[self setNeedsDisplay:YES];
}

-(void)drawCurrentLine {
	if ([currentLine count] > 1) {
		[[self currentPath] stroke];
	}
}

-(void)drawCurrentCharacters {
	NSArray *tempCharacters = [NSArray arrayWithArray:[currentCharacters copy]];
	if(tempCharacters != nil && [tempCharacters count] > 0){
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		for(int i = 0; i < [tempCharacters count]; i++){
			if ([tempCharacters objectAtIndex:i] != nil) {
				TICharacter *aChar = [[TICharacter alloc] initWithCharacter: [tempCharacters objectAtIndex:i]];
				NSAttributedString *attributedChar = [[NSAttributedString alloc] initWithString:[aChar character] attributes:[aChar attributesDictionary]];
				[[NSGraphicsContext currentContext] saveGraphicsState];
				NSPoint p = [[aChar location] pointValue];
				NSAffineTransform *transform = [NSAffineTransform transform];
				NSRect rect = [attributedChar boundingRectWithSize:NSZeroSize options:NSStringDrawingOneShot];
				[transform translateXBy:p.x yBy:p.y];
				[transform rotateByRadians:[[aChar angle] floatValue]];			
				[transform concat];
				[attributedChar drawWithRect:rect options:NSStringDrawingUsesLineFragmentOrigin];
				[[NSGraphicsContext currentContext] restoreGraphicsState];
			}
		}
		[pool release];
	}
}

-(void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

-(void)draw:(NSRect)dirtyRect {
	[[NSColor clearColor] set];
	NSRectFill(dirtyRect);
	[[self currentColor] set];
	[[self currentColor] setStroke];
	[self drawCurrentLine];
	[self drawCurrentCharacters];
}

-(void)drawRect:(NSRect)dirtyRect {
	[self lockFocus];
	if(!readyToDraw) [self prepareOpenGL];
	[self draw:dirtyRect];
	[self unlockFocus];
}

-(NSBezierPath *)currentPath {
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path moveToPoint:NSPointFromCGPoint([[currentLine objectAtIndex:0] origin])];
	for(int i = 1; i < [currentLine count]; i++){
		NSPoint p = NSMakePoint([[currentLine objectAtIndex:i] origin].x, [[currentLine objectAtIndex:i] origin].y);
		[path lineToPoint:p];
	}
	[path setLineWidth:2.0];
	return path;
}

- (void)lockFocus
{
	[super lockFocus];
	NSOpenGLContext* context = [self openGLContext];
	if ([context view] != self) {
		[context setView:self];
	}
	[context makeCurrentContext];
}

-(void)mouseDown:(NSEvent *)theEvent {
	[document processEvent:theEvent];
}

-(void)mouseDragged:(NSEvent *)theEvent {
	[document processEvent:theEvent];
	[self setNeedsDisplay:YES];
}

-(void)mouseUp:(NSEvent *)theEvent {
	[document processEvent:theEvent];
}

-(void)reshape {
	[super reshape];
	glViewport( 0, 0, (GLsizei)[self frame].size.width, (GLsizei)[self frame].size.height );
}

-(void)setCurrentLineToBeDrawn:(NSArray *)pointArray {
	currentLine = nil;
	currentLine = [pointArray copy];
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"CanvasViewNeedsDisplay" object:nil]];
}

-(void)setCharactersToBeDrawn:(NSArray *)characterArray {
	//[currentCharacters removeAllObjects];
	[currentCharacters addObjectsFromArray:characterArray];
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"CanvasViewNeedsDisplay" object:nil]];
}
@end
