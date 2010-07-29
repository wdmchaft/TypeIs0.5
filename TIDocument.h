//
//  TIDocument.h
//  TypeIs0.5
//
//  Created by collab-macpro on 10-07-23.
//  Copyright 2010 Travis Kirton. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TIWindow.h"
#import "CanvasView.h"
#import "ControlledIKImageView.h"
#import "TILineManager.h"
#import "TITextStorage.h"

@interface TIDocument : NSDocument {
	NSColor *foregroundColor, *backgroundColor;
	NSFont	*currentFont;
	NSURL	*imageURL, *textURL, *currentPDFURL;
	
	NSUInteger	_currentMode;
	CGFloat		_currentWeight;
	CGSize		_originalSize;
	CGPoint		_adjustedOrigin;
	CGRect		_viewRect;
	
	IBOutlet TIWindow	* _backgroundWindow;
	IBOutlet TIWindow	* _canvasWindow;
	IBOutlet CanvasView		* _canvasView;
	IBOutlet ControlledIKImageView	* _backgroundView;
	IBOutlet ControlledIKImageView	* _foregroundView;
    NSDictionary	*	_imageProperties;
    NSString		*	_imageUTType;
    IKSaveOptions	*	_saveOptions;
	
	TILineManager	*	_lineManager;
	TITextStorage	*	_textStorage;
	
	NSMutableArray	*	_storedCharacters;
}

-(IBAction)setWindowOrder:(id)sender;
-(IBAction)doZoom:(id)sender;
-(IBAction)switchToolMode:(id)sender;
-(IBAction)saveTextImage:(id)sender;
-(IBAction)savePDF:(id)sender;
-(void)saveTextImagePanelDidEnd:(NSSavePanel *)panel returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
-(void)savePDFPanelDidEnd:(NSSavePanel *)panel returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
-(IBAction)flushToPDF:(id)sender;
-(void)setImage:(NSURL *)image andText:(NSURL *)text;
-(void)setWindowSize;

-(void)keyDown:(NSEvent *)theEvent;

-(void)processEvent:(NSEvent *)theEvent;

@property(readwrite,retain) NSColor	* foregroundColor;
@property(readwrite,retain) NSColor	* backgroundColor;
@property(readwrite,retain) NSFont	* currentFont;
@property(readwrite,retain) NSURL	* imageURL;
@property(readwrite,retain) NSURL	* textURL;
@property(readwrite,retain) NSURL	* currentPDFURL;
@end
