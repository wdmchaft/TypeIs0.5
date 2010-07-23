//
//  ControlledIKImageView.h
//  TypeIs0.5
//
//  Created by collab-macpro on 10-06-29.
//  Copyright 2010 Travis Kirton. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "ScrollViewWorkaround.h"

@interface ControlledIKImageView : IKImageView {
	BOOL		adjustOriginX, adjustOriginY;
	IBOutlet	ScrollViewWorkaround *_scrollView;
	NSUInteger	xFrameAdjustment, yFrameAdjustment;  
}

-(void)adjustFrame;
-(ScrollViewWorkaround *)scrollView;

@end