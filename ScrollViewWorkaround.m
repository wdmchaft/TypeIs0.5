//
//  ScrollViewWorkaround.m
//  IKImageViewDemo
//
//  Created by Nicholas Riley on 1/25/10.
//  Copyright 2010 Nicholas Riley. All rights reserved.
//

#import "ScrollViewWorkaround.h"
#import <Quartz/Quartz.h>

@interface IKImageClipView : NSClipView
- (NSRect)docRect;
@end

@implementation ScrollViewWorkaround

- (void)reflectScrolledClipView:(NSClipView *)cView;
{
    NSView *_nsImageView = [self documentView];
    [super reflectScrolledClipView:cView];
    if ([_nsImageView isKindOfClass:[IKImageView class]] &&
	 [[self contentView] isKindOfClass:[IKImageClipView class]] &&
	 [[self contentView] respondsToSelector:@selector(docRect)]) {
	NSSize docSize = [(IKImageClipView *)[self contentView] docRect].size;
	NSSize scrollViewSize = [self contentSize];
	// NSLog(@"doc %@ scrollView %@", NSStringFromSize(docSize), NSStringFromSize(scrollViewSize));
	if (docSize.height > scrollViewSize.height || docSize.width > scrollViewSize.width)
	 ((IKImageView *)_nsImageView).autohidesScrollers = NO;
	else
	 ((IKImageView *)_nsImageView).autohidesScrollers = YES;
    }
//	printf("rect(%4.2f,%4.2f,%4.2f,%4.2f)\n", [self documentVisibleRect].origin.x,[self documentVisibleRect].origin.y,[self documentVisibleRect].size.width,[self documentVisibleRect].size.height);
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"ScrollViewDidChange" object:nil]];
}
@end
