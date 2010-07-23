//
//  TIDocument.m
//  TypeIs0.5
//
//  Created by collab-macpro on 10-07-23.
//  Copyright 2010 Travis Kirton. All rights reserved.
//

#import "TIDocument.h"

@interface TIDocument (private)
-(void)setupEventNotificationObservers;
-(void)createBackgroundImageFromURL:(NSURL*)url;
-(void)initializeTypeIsFromURL:(NSURL *)url;
-(int)convertFileTypeToInt:(NSString *)type;
-(void)setCurrentLineToBeDrawn;
-(void)drawRandomlyToIKImageView;
-(void)drawLineToIKImageView;
-(void)drawCharactersToIKImageView;	
-(void)drawPathToIKImageView:(CGMutablePathRef)aPath;
-(BOOL)zoomedImageIsLargerThanVisibleRect:(CGFloat)zoomFactor ;
-(void)setViewRect:(id)sender;
-(void)adjustForegroundView;
-(void)windowDidMove:(NSNotification *)notification;
-(NSData *)imageData:(CGImageRef)imageRef usingImageType:(NSString *)type;
@end

@implementation TIDocument
@synthesize foregroundColor, backgroundColor, currentFont, imageURL, textURL;

- (id)init
{
    self = [super init];
    if (self) {
		[self setForegroundColor:[[NSColor colorWithDeviceRed:1.0f green:0.0f blue:0.2f alpha:1.0f] colorUsingColorSpace:[NSColorSpace genericRGBColorSpace]]];
		[self setBackgroundColor:[[NSColor colorWithDeviceRed:0.22f green:0.33f blue:1.0f alpha:1.0f] colorUsingColorSpace:[NSColorSpace genericRGBColorSpace]]];
		[self setCurrentFont:[NSFont userFontOfSize:10.0f]];
		[self setupEventNotificationObservers];
		_storedCharacters = [[[NSMutableArray alloc] initWithCapacity:0] retain];
	}
    return self;
}

-(NSString *)fileType {
	return @"typeis";
}

- (NSString *)windowNibName
{
    return @"TIDocument";
}

-(void)setupEventNotificationObservers {
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(adjustForegroundView)
												 name:@"NSApplicationDidFinishLaunchingNotification" 
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(setWindowOrder:)
												 name:@"NSApplicationDidFinishLaunchingNotification" 
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(setWindowOrder:)
												 name:@"NSWindowDidBecomeKeyNotification"
											   object:nil];
	/*
	 [[NSNotificationCenter defaultCenter] addObserver:self
	 selector:@selector(drawLineToIKImageView)
	 name:@"MouseCursorLineCompleted"
	 object:nil];
	 
	 [[NSNotificationCenter defaultCenter] addObserver:self
	 selector:@selector(drawCharactersToIKImageView)
	 name:@"MouseCursorLineCompleted"
	 object:nil];
	 */
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(setWindowOrder:)
												 name:@"ControllerDidSwitchToolMode"
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(setViewRect:)
												 name:@"ScrollViewDidChange"
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(setViewRect:)
												 name:@"ControllerDidDoZoom"
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(createForegroundImage)
												 name:@"ControllerDidOpenImage"
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(setCurrentLineToBeDrawn)
												 name:@"CurrentLineShouldBeDrawn"
											   object:nil];	
}

- (BOOL)prepareSavePanel:(NSSavePanel *)sp
{
    // assign defaults for the save panel
    [sp setTitle:@"Save image"];
    [sp setExtensionHidden:NO];
    return YES;
}

-(void)windowDidMove:(NSNotification *)notification {
	switch (_currentMode) {
		case DRAWING_MODE:
			[_backgroundWindow setFrame:[_canvasWindow frame] display:YES];
			break;
		case PAN_ZOOM_MODE:
			[_canvasWindow setFrame:[_backgroundWindow frame] display:YES];
			break;
	}
}

-(IBAction)saveTextImage:(id)sender{
	if (_currentMode == DRAWING_MODE) {
		[self switchToolMode:sender];
	}
	NSSavePanel * savePanel = [NSSavePanel savePanel];
    
    _saveOptions = [[IKSaveOptions alloc] initWithImageProperties: _imageProperties
                                                      imageUTType: _imageUTType];
    
    [_saveOptions addSaveOptionsAccessoryViewToSavePanel: savePanel];
    
    NSString * fileName = [[_backgroundWindow representedFilename] lastPathComponent];
    
    [savePanel beginSheetForDirectory: NULL
                                 file: fileName
                       modalForWindow: _backgroundWindow
                        modalDelegate: self
                       didEndSelector: @selector(saveTextImagePanelDidEnd:returnCode:contextInfo:) 
                          contextInfo: NULL];
}

-(void)saveTextImagePanelDidEnd:(NSSavePanel *)panel returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo{
    // save the image
    
    if (returnCode == NSOKButton)
    {
        NSString * path = [panel filename];
        NSString * newUTType = [_saveOptions imageUTType];
        CGImageRef image;
		
        // get the current image from the image view
        image = [_foregroundView image];
        
        if (image)
        {
            // use ImageIO to save the image in the user specified format
            NSURL *               url = [NSURL fileURLWithPath: path];
            CGImageDestinationRef dest = CGImageDestinationCreateWithURL((CFURLRef)url, (CFStringRef)newUTType, 1, NULL);
            
            if (dest)
            {
                CGImageDestinationAddImage(dest, image, (CFDictionaryRef)[_saveOptions imageProperties]);
                CGImageDestinationFinalize(dest);
                CFRelease(dest);
            }
        } else
        {
            NSLog(@"*** saveImageToPath - no image");
        }
    }
}

-(IBAction)savePDF:(id)sender{
	if (_currentMode == DRAWING_MODE) {
		[self switchToolMode:sender];
	}
	
	NSSavePanel * savePanel = [NSSavePanel savePanel];
    NSString * fileName = [[_backgroundWindow representedFilename] lastPathComponent];
    [savePanel beginSheetForDirectory: NULL
                                 file: fileName
                       modalForWindow: _backgroundWindow
                        modalDelegate: self
                       didEndSelector: @selector(savePDFPanelDidEnd:returnCode:contextInfo:) 
                          contextInfo: NULL];
}

-(void)savePDFPanelDidEnd:(NSSavePanel *)panel returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo{
    // save the image
    if (returnCode == NSOKButton)
    {
        CFURLRef url = (CFURLRef)[NSURL fileURLWithPath:[panel filename]];
		
		NSMutableData *data = [[[NSMutableData alloc] init] autorelease];
		CGDataConsumerRef consumer = CGDataConsumerCreateWithCFData((CFMutableDataRef)data);
		CGRect bounds = CGRectMake(0, 0, _originalSize.width, _originalSize.height);
        
		CGContextRef context = CGPDFContextCreateWithURL(url, &bounds, NULL);
		CGContextBeginPage(context, &bounds);
		
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		for(TICharacter *aChar in _storedCharacters){
			NSAttributedString *attributedChar = [[NSAttributedString alloc] initWithString:[aChar character] attributes:[aChar attributesDictionary]];
			CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef)attributedChar);
			CGRect  imageBounds = CTLineGetImageBounds(line, context);
			float angle = [[aChar angle] floatValue];
			NSPoint p = [[aChar location] pointValue];
			NSPoint rotationPosition;
			rotationPosition.x = imageBounds.origin.x*cos(angle);
			rotationPosition.y = imageBounds.origin.x*sin(angle);
			// doesn't work yet
			CGContextSetFillColorSpace(context,CGColorSpaceCreateDeviceRGB());
			
			NSColor *color = [[[NSColor alloc] init] autorelease];
			color = [[[aChar attributesDictionary] objectForKey:NSForegroundColorAttributeName] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
			CGFloat components[4];
			[color getRed:&components[0] green:&components[1] blue:&components[2] alpha:&components[3]];
			CGContextSetRGBFillColor(context,components[0],components[1],components[2],components[3]);			
			CGContextSaveGState(context);
			//translate from the rotation position to the view position
			CGContextTranslateCTM(context,p.x-rotationPosition.x,p.y-rotationPosition.y);
			//rotate the context
			CGContextRotateCTM(context,angle);
			//draw the line
			CTLineDraw(line,context);
			CGContextRestoreGState(context);
			
		}
		
		[pool release];
		
		CGContextEndPage(context);
		CGContextRelease(context);
		CGDataConsumerRelease(consumer);
		
        if (true)
        {
        } else
        {
            NSLog(@"*** savePDF - no image");
        }
    }
}

#pragma mark actions
-(IBAction)setWindowOrder:(id)sender {
	switch (_currentMode) {
		case DRAWING_MODE:
			[_canvasWindow makeKeyAndOrderFront:sender];
			[_backgroundWindow orderWindow:NSWindowBelow relativeTo:[_canvasWindow windowNumber]];
			//printf("drawing mode\n");
			break;
		case PAN_ZOOM_MODE:
			[_backgroundWindow makeKeyAndOrderFront:sender];
			[_canvasWindow orderWindow:NSWindowBelow relativeTo:[_backgroundWindow windowNumber]];
			//printf("pan/zoom mode\n");
			break;
	}	
}

-(void)adjustForegroundView {
	CGFloat zoomFactor = [_backgroundView zoomFactor];
	[_backgroundView setZoomFactor:zoomFactor];
	[_foregroundView setZoomFactor:zoomFactor];
	[_canvasView setZoomFactor:zoomFactor];
	[_foregroundView adjustFrame];
}

- (void)windowControllerDidLoadNib:(NSWindowController *)windowController
{
    [super windowControllerDidLoadNib:windowController];
	[self createBackgroundImageFromURL:[self imageURL]];
	[self initializeTypeIsFromURL:[self textURL]];
	[self setWindowOrder:nil];
}

-(void)dealloc {
	[super dealloc];
}

-(void)setImage:(NSURL *)image andText:(NSURL *)text {	
	[self setImageURL:image];
	[self setTextURL:text];
	printf("%s\n",[[[self imageURL] absoluteString] UTF8String]);
	printf("%s\n",[[[self textURL] absoluteString] UTF8String]);
}

-(void)processEvent:(NSEvent *)theEvent {
	[_lineManager processEvent:theEvent];
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"CurrentLineShouldBeDrawn" object:nil]];
}

-(void)keyDown:(NSEvent *)theEvent {
	CGFloat components[4];
	[[self backgroundColor] getRed:&components[0] green:&components[1] blue:&components[2] alpha:&components[3]];
	switch ([theEvent keyCode]) {
		case 5:
			if ([theEvent modifierFlags] & NSShiftKeyMask) {
				components[1] -= 0.01f;
			} else	components[1] += 0.01f;
			break;
		case 11:
			if ([theEvent modifierFlags] & NSShiftKeyMask) {
				components[2] -= 0.01f;
			} else  components[2] += 0.01f;
			break;
		case 15:
			if ([theEvent modifierFlags] & NSShiftKeyMask) {
				components[0] -= 0.01f;
			} else	components[0] += 0.01f;
			break;
		case 35:
			printf("color:(%4.2f,%4.2f,%4.2f,%4.2f)\n",components[0],components[1],components[2],components[3]);
			break;
			
		default:
			break;
	}
	[self setBackgroundColor:[NSColor colorWithCalibratedRed:components[0] green:components[1] blue:components[2] alpha:components[3]]];
}


- (IBAction)doZoom:(id)sender
{
	if(_currentMode == PAN_ZOOM_MODE){
		NSInteger zoom;
		CGFloat zoomFactor;
		
		if ([sender isKindOfClass: [NSSegmentedControl class]])
			zoom = [sender selectedSegment];
		else
			zoom = [sender tag];
		switch (zoom)
		{
				
			case 0:
				zoomFactor = [_backgroundView zoomFactor];
				[_backgroundView setZoomFactor: zoomFactor * ZOOM_IN_FACTOR];
				[_foregroundView setZoomFactor: zoomFactor * ZOOM_IN_FACTOR];
				[_canvasView setZoomFactor: zoomFactor * ZOOM_IN_FACTOR];
				[_lineManager setZoomFactor: zoomFactor * ZOOM_IN_FACTOR];
				[_foregroundView adjustFrame];
				[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"ControllerDidDoZoom" object:nil]];	
				break;
			case 1:
				zoomFactor = [_backgroundView zoomFactor];
				if([self zoomedImageIsLargerThanVisibleRect:zoomFactor * ZOOM_OUT_FACTOR] ){
					[_backgroundView setZoomFactor: zoomFactor * ZOOM_OUT_FACTOR];
					[_foregroundView setZoomFactor: zoomFactor * ZOOM_OUT_FACTOR];
					[_lineManager setZoomFactor:zoomFactor * ZOOM_OUT_FACTOR];
					[_foregroundView adjustFrame];
					[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"ControllerDidDoZoom" object:nil]];	
				} 
				break;
		}
	}
}

- (void)changeFont:(id)sender   
{
	NSFont *oldFont = [self currentFont];
	NSFont *newFont = [sender convertFont:oldFont];
	[self setCurrentFont:newFont];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ControllerDidChangeFont" object:self userInfo:[NSDictionary dictionaryWithObject:[self currentFont] forKey:@"font"]];
}

-(void)changeColor:(id)sender{
	[self setForegroundColor:[[sender color] colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]]];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ControllerDidChangeColor" object:self userInfo:[NSDictionary dictionaryWithObject:[[self foregroundColor]colorUsingColorSpace:[NSColorSpace genericRGBColorSpace]] forKey:@"color"]];
}

- (IBAction)switchToolMode: (id)sender
{	
	NSUInteger newTool;
	newTool = [sender tag];	
	switch (newTool)
	{
		case 0:
			if(_currentMode == DRAWING_MODE){
				[sender setState:NSOffState];
				_currentMode = PAN_ZOOM_MODE;
				[self drawCharactersToIKImageView];
			} else {
				[sender setState:NSOnState];
				_currentMode = DRAWING_MODE;
			}
			break;
	}
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"ControllerDidSwitchToolMode" object:nil]];	
}

#pragma mark image creation
- (void)createBackgroundImageFromURL:(NSURL*)url
{
	//set the image
	[_backgroundView setImageWithURL:url];
	_originalSize = CGSizeMake(CGImageGetWidth([_backgroundView image]), CGImageGetHeight([_backgroundView image]));
	_viewRect = CGRectMake(0, 0, _originalSize.width, _originalSize.height);
	
	//set image properties
	[_backgroundView setBackgroundColor:[NSColor blackColor]];
    [_backgroundView setDoubleClickOpensImageEditPanel:NO];
    [_backgroundView setCurrentToolMode:IKToolModeNone];
    _backgroundView.editable = NO;
    _backgroundView.autoresizes = NO;
    _backgroundView.autohidesScrollers = NO;
    _backgroundView.hasHorizontalScroller = YES;
    _backgroundView.hasVerticalScroller = YES;
	
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"ControllerDidOpenImage" object:nil]];
}

-(void)createForegroundImage {
	CGImageRef  backgroundViewRef = [_backgroundView image];
	CGImageRef	foregroundViewRef = NULL;
	
	// The following code is adapted from:
	// http://www.gotow.net/creative/wordpress/?p=33
	
	CGContextRef	bitmapContext;
	void			*bitmapData;
	int				bitmapByteCount;
	int				bitmapBytesPerRow;
	CGSize			size = CGSizeMake(CGImageGetWidth(backgroundViewRef), CGImageGetHeight(backgroundViewRef));
	
	bitmapBytesPerRow	= size.width * 4;
	bitmapByteCount		= bitmapBytesPerRow * size.height;
	
	bitmapData = malloc(bitmapByteCount);
	
	if(bitmapData == NULL){
		printf("null bitmap data");
		exit(0);
	}
	printf("%4.2f,%4.2f",size.width,size.height);
	bitmapContext = CGBitmapContextCreate(bitmapData, size.width, size.height, 8, bitmapBytesPerRow, CGColorSpaceCreateDeviceRGB(), kCGImageAlphaPremultipliedFirst);
	
	if(bitmapContext == NULL){
		printf("null context data");
		exit(0);
	}
	
	foregroundViewRef = CGBitmapContextCreateImage(bitmapContext);
	
	[_foregroundView setImage:foregroundViewRef imageProperties:NULL];
	
	CGContextRelease(bitmapContext);
	// end of adapted gotow.net code
	[_foregroundView setBackgroundColor:[NSColor colorWithCalibratedWhite:1 alpha:0]];
    [_foregroundView setDoubleClickOpensImageEditPanel:NO];
    [_foregroundView setCurrentToolMode:IKToolModeNone];
	[_foregroundView zoomImageToFit:[_foregroundView enclosingScrollView]];
    _foregroundView.editable = NO;
    _foregroundView.autoresizes = NO;
    _foregroundView.autohidesScrollers = NO;
    _foregroundView.hasHorizontalScroller = YES;
    _foregroundView.hasVerticalScroller = YES;
}

#pragma mark typeis initialization
-(void)initializeTypeIsFromURL:(NSURL *)url{
	_lineManager = [[TILineManager sharedManager] retain];
	[_lineManager setCurrentFont:[self currentFont]];
	[_lineManager setCurrentColor:[self foregroundColor]];
	
	_textStorage	= [[TITextStorage sharedManager] retain];
	int type = [self convertFileTypeToInt:[url pathExtension]];
	switch (type) {
			/*
			 case _BYTES:
			 [_textStorage initWithBYTES:<#(const void *)bytes#> length:<#(NSUInteger)length#> encoding:<#(NSStringEncoding)encoding#>];
			 break;
			 case _CHARS:
			 [_textStorage initWithCHARS:(const unichar *)characters length:(NSUInteger)length];
			 break;
			 case _CSTRING:
			 [_textStorage initWithCSTRING:(const char *)nullTerminatedCString encoding:(NSStringEncoding)encoding];
			 break;
			 */
		case _DOC:
			[_textStorage initWithDOC:[NSData dataWithContentsOfURL:url]];
			break;
			/*
			 case _FILE:
			 [_textStorage initWith:[NSData dataWithContentsOfURL:url]];
			 break;
			 */
		case _HTML:
			[_textStorage initWithHTML:[NSData dataWithContentsOfURL:url]];
			break;
		case _RTF:
			[_textStorage initWithRTF:url];
			break;
		case _URL:
			[_textStorage initWithURL:url];
			break;
			/*
			 case _UTF8STRING:
			 [_textStorage initWithUTF8String:(const char *)bytes];
			 break;
			 */
		default:
			[_textStorage initWithDATA:[NSData dataWithContentsOfURL:url]];
			break;
	}
}

-(int)convertFileTypeToInt:(NSString *)type{
	if ([[type lowercaseString] isEqual:@"doc"]) {
		return _DOC;
	}
	else if ([[type lowercaseString] isEqual:@"html"]) {
		return _HTML;
	}
	else if ([[type lowercaseString] isEqual:@"rtf"]) {
		return _RTF;
	}
	return 0;
}

#pragma mark drawing
-(void)setCurrentLineToBeDrawn {
	[_canvasView setCurrentLineToBeDrawn:[[_lineManager getPointArray] copy]];
	NSArray *characterArray = [_lineManager getBufferedCharacters];
	//printf("%d ",[characterArray count]);
	if(characterArray != nil && [characterArray count] > 0){
		//printf("message");
		[_canvasView setCharactersToBeDrawn:characterArray];
	}
}

-(void)drawRandomlyToIKImageView {
	CGImageRef foregroundViewRef = [_foregroundView image];
	CGContextRef	bitmapContext;
	const UInt8		*bitmapData;
	int				bitmapByteCount;
	int				bitmapBytesPerRow;
	CGSize			size = CGSizeMake(CGImageGetWidth(foregroundViewRef), CGImageGetHeight(foregroundViewRef));
	bitmapBytesPerRow	= size.width *4;
	bitmapByteCount		= bitmapBytesPerRow * size.height;
	bitmapData = malloc(bitmapByteCount);
	
	bitmapData = CFDataGetBytePtr(CGDataProviderCopyData(CGImageGetDataProvider(foregroundViewRef)));
	
	if(bitmapData == NULL){
		printf("null bitmap data");
		exit(0);
	}
	
	bitmapContext = CGBitmapContextCreate((void*)bitmapData, size.width, size.height, 8, bitmapBytesPerRow, CGColorSpaceCreateDeviceRGB(), kCGImageAlphaPremultipliedFirst);
	
	if(bitmapContext == NULL){
		printf("null context data");
		exit(0);
	}
	
	CGContextSetRGBStrokeColor(bitmapContext, 1.0, 0.0, 0.0, 1.0);
    CGContextSetLineWidth(bitmapContext, 10.0);
    CGContextMoveToPoint(bitmapContext, 0,0);
    CGContextAddLineToPoint(bitmapContext, random()%(int)size.width, random()%(int)size.height);
    CGContextStrokePath(bitmapContext);
	foregroundViewRef = CGBitmapContextCreateImage(bitmapContext);
	[_foregroundView setImage:foregroundViewRef imageProperties:NULL];
	[_foregroundView setZoomFactor:[_backgroundView zoomFactor]];
	[_foregroundView adjustFrame];
	CGContextRelease(bitmapContext);
}

-(void)drawLineToIKImageView {
	TICursorLine *aLine = [_lineManager getLastLine];
	if ([aLine length] > 2) {
		NSArray *points = [[NSArray alloc] initWithArray:[aLine getPointArray]];
		NSPoint p = NSPointFromCGPoint([[points objectAtIndex:0] origin]);
		
		p.x += _viewRect.origin.x-1;
		p.x /= [_foregroundView zoomFactor];
		p.y += _viewRect.origin.y-16;
		p.y /= [_foregroundView zoomFactor];
		
		CGMutablePathRef pathRef = CGPathCreateMutable();
		CGPathMoveToPoint(pathRef, NULL, p.x, p.y);
		
		for(int i = 1; i < [points count]; i++){
			p = NSPointFromCGPoint([[points objectAtIndex:i] origin]);
			p.x += _viewRect.origin.x;
			p.x /= [_foregroundView zoomFactor];
			p.y += _viewRect.origin.y -16;
			p.y /= [_foregroundView zoomFactor];
			CGPathAddLineToPoint(pathRef, NULL, p.x, p.y);
		}
		
		[self drawPathToIKImageView:pathRef];
		CGPathRelease(pathRef);
	}
}


-(void)drawCharactersToIKImageView {
	NSArray *tempCharacters = [NSArray arrayWithArray:[_canvasView getCurrentCharacters]];
	if(tempCharacters != nil && [tempCharacters count] > 0){
		
		CGImageRef foregroundViewRef = [_foregroundView image];
		CGContextRef	bitmapContext;
		const UInt8		*bitmapData;
		int				bitmapByteCount;
		int				bitmapBytesPerRow;
		CGSize			size = CGSizeMake(CGImageGetWidth(foregroundViewRef), CGImageGetHeight(foregroundViewRef));
		bitmapBytesPerRow	= size.width *4;
		bitmapByteCount		= bitmapBytesPerRow * size.height;
		bitmapData = malloc(bitmapByteCount);
		
		CGDataProviderRef	imageDataProviderRef = CGImageGetDataProvider(foregroundViewRef);
		CFDataRef			dataProviderCopiedData = CGDataProviderCopyData(imageDataProviderRef);
		bitmapData = CFDataGetBytePtr(dataProviderCopiedData);
		
		if(bitmapData == NULL){
			printf("null bitmap data");
			exit(0);
		}
		
		bitmapContext = CGBitmapContextCreate((void*)bitmapData, size.width, size.height, 8, bitmapBytesPerRow, CGColorSpaceCreateDeviceRGB(), kCGImageAlphaPremultipliedFirst);
		
		if(bitmapContext == NULL){
			printf("null context data");
			exit(0);
		}
		
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		NSGraphicsContext *gc = [NSGraphicsContext graphicsContextWithGraphicsPort:(void*)bitmapContext flipped:NO];
		[NSGraphicsContext saveGraphicsState];
		[NSGraphicsContext setCurrentContext:gc];
		for(int i = 0; i < [tempCharacters count]; i++){
			if ([tempCharacters objectAtIndex:i] != nil) {
				TICharacter *aChar = [[TICharacter alloc] initWithCharacter:[tempCharacters objectAtIndex:i]];
				//NSString *character = [[tempCharacters objectAtIndex:i] character];
				NSString *fontName = [[[[tempCharacters objectAtIndex:i] attributesDictionary] valueForKey:NSFontAttributeName] fontName];
				CGFloat newFontSize = [[[aChar attributesDictionary] valueForKey:NSFontAttributeName] pointSize] / [_backgroundView zoomFactor];
				NSMutableDictionary *attribs = [NSMutableDictionary dictionaryWithDictionary:[aChar attributesDictionary]];
				[attribs setValue:[NSFont fontWithName:fontName size:newFontSize] forKey:NSFontAttributeName];
				[aChar setAttributesDictionary:attribs];
				NSAttributedString *attributedChar = [[NSAttributedString alloc] initWithString:[aChar character] attributes:[aChar attributesDictionary]];
				CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef)attributedChar);
				CGRect  imageBounds = CTLineGetImageBounds(line, bitmapContext);
				float angle = [[aChar angle] floatValue];
				NSPoint p = [[aChar location] pointValue];
				p.x += _viewRect.origin.x;
				p.x /= [_foregroundView zoomFactor];
				p.y += _viewRect.origin.y-16;
				p.y /= [_foregroundView zoomFactor];
				[aChar setLocation:[NSValue valueWithPoint:p]];
				[_storedCharacters addObject:aChar];
				
				NSPoint rotationPosition;
				rotationPosition.x = imageBounds.origin.x*cos(angle);
				rotationPosition.y = imageBounds.origin.x*sin(angle);
				// doesn't work yet
				CGContextSetFillColorSpace(bitmapContext,CGColorSpaceCreateDeviceRGB());
				
				NSColor *color = [[[NSColor alloc] init] autorelease];
				color = [[attribs objectForKey:NSForegroundColorAttributeName] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
				CGFloat components[4];
				[color getRed:&components[0] green:&components[1] blue:&components[2] alpha:&components[3]];
				CGContextSetRGBFillColor(bitmapContext,components[0],components[1],components[2],components[3]);			
				CGContextSaveGState(bitmapContext);
				//translate from the rotation position to the view position
				CGContextTranslateCTM(bitmapContext,p.x-rotationPosition.x,p.y-rotationPosition.y);
				//rotate the context
				CGContextRotateCTM(bitmapContext,angle);
				//draw the line
				CTLineDraw(line,bitmapContext);
				CGContextRestoreGState(bitmapContext);
			}
		}
		
		[pool release];
		/* end drawing code */
		
		foregroundViewRef = CGBitmapContextCreateImage(bitmapContext);
		[_foregroundView setImage:foregroundViewRef imageProperties:NULL];
		[_foregroundView setZoomFactor:[_backgroundView zoomFactor]];
		[_foregroundView adjustFrame];
		CGContextRelease(bitmapContext);	
	}
}	

-(void)drawPathToIKImageView:(CGMutablePathRef)aPath {
	CGPathRetain(aPath);
	CGImageRef foregroundViewRef = [_foregroundView image];
	CGContextRef	bitmapContext;
	const UInt8			*bitmapData;
	int				bitmapByteCount;
	int				bitmapBytesPerRow;
	CGSize			size = CGSizeMake(CGImageGetWidth(foregroundViewRef), CGImageGetHeight(foregroundViewRef));
	bitmapBytesPerRow	= size.width *4;
	bitmapByteCount		= bitmapBytesPerRow * size.height;
	bitmapData = malloc(bitmapByteCount);
	
	CGDataProviderRef	imageDataProviderRef = CGImageGetDataProvider(foregroundViewRef);
	CFDataRef			dataProviderCopiedData = CGDataProviderCopyData(imageDataProviderRef);
	bitmapData = CFDataGetBytePtr(dataProviderCopiedData);
	
	if(bitmapData == NULL){
		printf("null bitmap data");
		exit(0);
	}
	
	bitmapContext = CGBitmapContextCreate((void*)bitmapData, size.width, size.height, 8, bitmapBytesPerRow, CGColorSpaceCreateDeviceRGB(), kCGImageAlphaPremultipliedFirst);
	
	if(bitmapContext == NULL){
		printf("null context data");
		exit(0);
	}
	
	CGContextSetRGBStrokeColor(bitmapContext, 1.0, 0.0, 0.0, 1.0);
    CGContextSetLineWidth(bitmapContext, 1.0/[_foregroundView zoomFactor]);
	CGContextAddPath(bitmapContext, aPath);
    CGContextStrokePath(bitmapContext);
	foregroundViewRef = CGBitmapContextCreateImage(bitmapContext);
	[_foregroundView setImage:foregroundViewRef imageProperties:NULL];
	[_foregroundView setZoomFactor:[_backgroundView zoomFactor]];
	[_foregroundView adjustFrame];
	CGContextRelease(bitmapContext);
	CGPathRelease(aPath);
}

-(BOOL)zoomedImageIsLargerThanVisibleRect:(CGFloat)zoomFactor {
	BOOL widthIsLarger = YES;
	BOOL heightIsLarger = YES;
	CGFloat viewWidth = [[_foregroundView scrollView] documentVisibleRect].size.width;
	CGFloat viewHeight = [[_foregroundView scrollView] documentVisibleRect].size.height;
	CGFloat modifiedWidth = _originalSize.width * zoomFactor;
	CGFloat modifiedHeight = _originalSize.height * zoomFactor;
	if (modifiedWidth < viewWidth) {
		widthIsLarger = NO;
	}
	if (modifiedHeight < viewHeight) {
		heightIsLarger = NO;
	}
	
	if (widthIsLarger == NO || heightIsLarger == NO) {
		return NO;
	}
	return YES;
}

-(void)setViewRect:(id)sender {
	CGFloat zoomFactor = [_foregroundView zoomFactor];
	_viewRect.size.width = _originalSize.width*zoomFactor;
	_viewRect.size.height = _originalSize.height*zoomFactor;
	
	if(_viewRect.size.width < [_foregroundView frame].size.width){
		_viewRect.origin.x = [_foregroundView frame].size.width/2 - _viewRect.size.width/2;
	} else {
		_viewRect.origin.x = [[_foregroundView scrollView] documentVisibleRect].origin.x;
	}
	if(_viewRect.size.height < [_foregroundView frame].size.height){
		_viewRect.origin.y = [_foregroundView frame].size.height/2 - _viewRect.size.height/2;
	} else {
		_viewRect.origin.y = [[_foregroundView scrollView] documentVisibleRect].origin.y;
	}
}

-(BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper ofType:(NSString *)typeName error:(NSError **)outError {
	
    if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
	return YES;
}

-(NSFileWrapper *)fileWrapperOfType:(NSString *)typeName error:(NSError **)outError {
	
	NSFileWrapper *fw = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:[NSDictionary dictionary]];
	NSString *extension = [imageURL pathExtension];
	[fw addRegularFileWithContents:[self imageData:[_backgroundView image] usingImageType:extension] preferredFilename:[[@"backgroundImage" stringByAppendingString:@"."] stringByAppendingString:extension]];
	[fw addRegularFileWithContents:[self imageData:[_foregroundView image] usingImageType:extension] preferredFilename:[[@"foregroundImage" stringByAppendingString:@"."] stringByAppendingString:extension]];
	/*
	if ([extension isEqualToString:@"jpg"] || [extension isEqualToString:@"jpeg"]) {
		[fw addRegularFileWithContents:[self JPEGData:[_backgroundView image]] preferredFilename:[[@"backgroundImage" stringByAppendingString:@"."] stringByAppendingString:extension]];
		[fw addRegularFileWithContents:[self JPEGData:[_foregroundView image]] preferredFilename:[[@"foregroundImage" stringByAppendingString:@"."] stringByAppendingString:extension]];
	} else if([extension isEqualToString:@"png"]) {
		[fw addRegularFileWithContents:[self PNGData:[_backgroundView image]] preferredFilename:[[@"backgroundImage" stringByAppendingString:@"."] stringByAppendingString:extension]];
		[fw addRegularFileWithContents:[self PNGData:[_foregroundView image]] preferredFilename:[[@"foregroundImage" stringByAppendingString:@"."] stringByAppendingString:extension]];
	} else if ([extension isEqualToString:@"tiff"]) {
		[fw addRegularFileWithContents:[self TIFFData:[_backgroundView image]] preferredFilename:[[@"backgroundImage" stringByAppendingString:@"."] stringByAppendingString:extension]];
		[fw addRegularFileWithContents:[self TIFFData:[_foregroundView image]] preferredFilename:[[@"foregroundImage" stringByAppendingString:@"."] stringByAppendingString:extension]];
	}
	*/
	return fw;
}

-(NSData *)imageData:(CGImageRef)imageRef usingImageType:(NSString *)type {
	CFMutableDataRef dataRef = CFDataCreateMutable(kCFAllocatorDefault, 0);	
	CGImageDestinationRef destRef = CGImageDestinationCreateWithData(dataRef, (CFStringRef)[@"public." stringByAppendingString:type], 1, nil);
	if ([type isEqualToString:@"jpg"] || [type isEqualToString:@"jpeg"]) {
		CFMutableDictionaryRef jpegSaveOptions = CFDictionaryCreateMutable(nil,0,&kCFTypeDictionaryKeyCallBacks,&kCFTypeDictionaryValueCallBacks);
		CFDictionarySetValue(jpegSaveOptions, kCGImageDestinationLossyCompressionQuality,[NSNumber numberWithFloat:1.0]);	// set the compression quality here
		CGImageDestinationAddImage(destRef,imageRef, jpegSaveOptions);
	} else if ([type isEqualToString:@"png"]) {
		CGImageDestinationAddImage(destRef,imageRef, NULL);
	}
	else if ([type isEqualToString:@"tiff"]) {
		CFMutableDictionaryRef tiffSaveoptions = CFDictionaryCreateMutable(nil, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		CFMutableDictionaryRef tiffCompression = CFDictionaryCreateMutable(nil, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		
		int compression = NSTIFFCompressionLZW;
		CFDictionarySetValue(tiffCompression, kCGImagePropertyTIFFCompression, CFNumberCreate(NULL, kCFNumberIntType, &compression));	
		CFDictionarySetValue(tiffSaveoptions, kCGImagePropertyTIFFDictionary, tiffCompression);
		CGImageDestinationAddImage(destRef, imageRef, tiffSaveoptions);
	}
	CGImageDestinationFinalize(destRef);
	return (NSData *)dataRef;
}
@end
