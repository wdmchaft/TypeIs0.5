//
//  CanvasWindow.m
//  TypeIs0.5
//
//  Created by collab-macpro on 10-06-29.
//  Copyright 2010 Travis Kirton. All rights reserved.
//

#import "TIWindow.h"
#import "TIDocument.h"

@implementation TIWindow

-(void)awakeFromNib {
}

-(void)performClose:(id)sender {
	[document close];
	[self close];
}

@end
