//
//  TICharacter.h
//  TypeIs0.5
//
//  Created by collab-macpro on 10-03-18.
//  Copyright 2010 Travis Kirton. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TICharacter : NSObject {
	NSNumber			*angle;
	NSMutableDictionary	*attributesDictionary;
	NSString			*character;
	NSValue				*location;
}

@property (readwrite, retain) NSNumber		*angle;
@property (readwrite, retain) NSMutableDictionary	*attributesDictionary;
@property (readwrite, retain) NSString		*character;
@property (readwrite, retain) NSValue		*location;

-(id)initWithAngle:(NSNumber *)angle attributes:(NSDictionary *)attributes character:(NSString *)string andPositionValue:(NSValue *)location;
-(id)initWithCharacter:(TICharacter *)aCharacter;
@end