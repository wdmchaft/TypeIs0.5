//
//  TIPoint.h
//  TypeIs0.5
//
//  Created by collab-macpro on 10-03-09.
//  Copyright 2010 Travis Kirton. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>

/*
 NOTE:	Possible to add other data objects & init methods (e.g. withPressure)
		Timestamp will allow for replaying the creation of artworks
 */
@interface TIPoint : NSObject {
	@private
	CFBooleanRef angleIsSet, distanceIsSet;
	CGPoint origin;
	CGFloat angle, distance;
	CFTimeInterval timeStamp; //in most cases will be relative to the beginning of the drawing
}

-(id)initWithOrigin:(CGPoint)point;
-(id)initWithOrigin:(CGPoint)point andTimeStamp:(CFTimeInterval)time;
-(void)setAngle:(CGFloat)theta;
-(void)setDistance:(CGFloat)totalDistance;
-(CGFloat)distanceToPoint:(CGPoint)point;
-(CGFloat)distanceToTIPoint:(TIPoint *)point;
+(TIPoint *)pointWithPoint:(TIPoint *)point;
-(CFBooleanRef)angleIsSet;
-(CFBooleanRef)distanceIsSet;

@property (readonly) CGPoint origin;
@property (readonly) CGFloat angle;		
@property (readonly) CGFloat distance;
@property (readonly) CFTimeInterval timeStamp;	
@end
