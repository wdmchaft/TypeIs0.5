//
//  TIDocumentController.m
//  TypeIs0.5
//
//  Created by collab-macpro on 10-07-20.
//  Copyright 2010 Travis Kirton. All rights reserved.
//

#import "TIDocumentController.h"
#import "TIDocument.h"

@implementation TIDocumentController
-(id)init {
	self = [super init];
	if (self != nil) {
		[self newDocument:nil];
	}
	return self;
}

-(IBAction)newDocument:(id)sender{
	
	/* Doing this by hand because we need to instantiate the image and text prior to opening the window */
	
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setAllowsMultipleSelection:NO];
	
	//Run an OpenPanel to set image type & location
	[openPanel setTitle:@"Choose A Background Image"];
	[openPanel setAllowedFileTypes:[NSArray arrayWithObjects:@"jpg",@"jpeg",@"tiff",@"png",nil]];

	if ([openPanel runModal] == NSFileHandlingPanelOKButton) {
		NSURL	*imageURL = [NSURL URLWithString:[[[openPanel URLs] objectAtIndex:0] absoluteString]];
		
		//Run an OpenPanel to set text type & location
		[openPanel setTitle:@"Choose A Text Source"];
		[openPanel setAllowedFileTypes:nil];
		if ([openPanel runModal] == NSFileHandlingPanelOKButton) {
			NSURL   *textURL		= [NSURL URLWithString:[[[openPanel URLs] objectAtIndex:0] absoluteString]];
			
			TIDocument *newDocument = [[TIDocument alloc] init];
			[newDocument setImage:imageURL andText:textURL];
			[newDocument makeWindowControllers];
			[newDocument showWindows];
			[self addDocument:newDocument];
		}
	}
}

@end
