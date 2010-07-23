//
//  CanvasWindow.h
//  TypeIs0.5
//
//  Created by collab-macpro on 10-06-29.
//  Copyright 2010 Travis Kirton. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TIDocument;

@interface TIWindow : NSWindow {
	IBOutlet NSWindow *	backgroundWindow;
	IBOutlet TIDocument *document;
}

@end