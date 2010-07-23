//
//  TIPoint.m
//  TypeIs0.5
//
//  Created by collab-macpro on 10-03-09.
//  Copyright 2010 Travis Kirton. All rights reserved.
//

#import "TIPoint.h"

@implementation TIPoint
@synthesize origin;
@synthesize angle;
@synthesize distance;
@synthesize timeStamp;

-(id)init {
	return [self initWithOrigin:CGPointMake(0, 0)];
}

-(id)initWithOrigin:(CGPoint)point {
	return [self initWithOrigin:point andTimeStamp:CFAbsoluteTimeGetCurrent()];
}

-(id)initWithOrigin:(CGPoint)point andTimeStamp:(CFTimeInterval)time {
	if(![super init])
		return nil;
	angleIsSet = kCFBooleanFalse;
	distanceIsSet = kCFBooleanFalse;
	angle = 0;
	origin = point;		//set only one time here, readonly after that
	timeStamp = time;	//set only one time here, readonly after that
	return self;
}

-(void)setAngle:(CGFloat)theta {
	if (angleIsSet == kCFBooleanFalse) {
		angle = theta;	//set only one time, readonly after that
		angleIsSet = kCFBooleanTrue;
	}
}

-(void)setDistance:(CGFloat)totalDistance {
	if(distanceIsSet == kCFBooleanFalse){
		distance = totalDistance;
		distanceIsSet = kCFBooleanTrue;
	}
}

-(CGFloat)distanceToPoint:(CGPoint)point {
	return (sqrt(pow(point.x-origin.x,2)+pow(point.y-origin.y,2)));
}

-(CGFloat)distanceToTIPoint:(TIPoint *)point {
	return [self distanceToPoint:[point origin]];
}

+(TIPoint *)pointWithPoint:(TIPoint *)point{
	TIPoint *p = [[[TIPoint alloc] initWithOrigin:[point origin] andTimeStamp:[point timeStamp]] autorelease];
	if([point distanceIsSet] == kCFBooleanTrue){
		[p setDistance:[point distance]];
	}
	if([point angleIsSet] == kCFBooleanTrue){
		[p setAngle:[point angle]];
	}
	return p;
}

-(CFBooleanRef)angleIsSet {
	if(angleIsSet == kCFBooleanTrue)
		return kCFBooleanTrue;
	return kCFBooleanFalse;
}

-(CFBooleanRef)distanceIsSet {
	if(distanceIsSet == kCFBooleanTrue)
		return kCFBooleanTrue;
	return kCFBooleanFalse;
}
@end
