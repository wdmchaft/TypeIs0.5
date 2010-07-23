//
//  ControlledIKImageView.m
//  TypeIs0.5
//
//  Created by collab-macpro on 10-06-29.
//  Copyright 2010 Travis Kirton. All rights reserved.
//

#import "ControlledIKImageView.h"

@implementation ControlledIKImageView
-(void)awakeFromNib {
	adjustOriginX = NO;
	adjustOriginY = NO;
	xFrameAdjustment = 7;
	yFrameAdjustment = 7;
}

-(void)adjustFrame {
	if([self imageSize].width * [self zoomFactor] <= [[self superview] frame].size.width){
		if (adjustOriginX == NO) {
			NSPoint newOrigin = [self frame].origin;
			newOrigin.x += xFrameAdjustment;
			[self setFrameOrigin:newOrigin];
			adjustOriginX = YES;
		}
	} else {
		if(adjustOriginX == YES){
			NSPoint newOrigin = [self frame].origin;
			newOrigin.x -= xFrameAdjustment;
			[self setFrameOrigin:newOrigin];
			adjustOriginX = NO;
		}
	}
	if([self imageSize].height * [self zoomFactor] <= [[self superview] frame].size.height){
		if (adjustOriginY == NO) {
			NSPoint newOrigin = [self frame].origin;
			newOrigin.y += yFrameAdjustment;
			[self setFrameOrigin:newOrigin];
			adjustOriginY = YES;
		}
	} else {
		if(adjustOriginY == YES){
			NSPoint newOrigin = [self frame].origin;
			newOrigin.y -= yFrameAdjustment;
			[self setFrameOrigin:newOrigin];
			adjustOriginY = NO;
		}
	}
}

-(void)setImageWithURL:(NSURL *)url {
	printf("%s\n",[[url absoluteString] UTF8String]);
	[super setImageWithURL:url];
}

-(ScrollViewWorkaround *)scrollView {
	return _scrollView;
}
@end
