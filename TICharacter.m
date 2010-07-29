//
//  TICharacter.m
//  TypeIs0.5
//
//  Created by collab-macpro on 10-03-18.
//  Copyright 2010 Travis Kirton. All rights reserved.
//

#import "TICharacter.h"


@implementation TICharacter
@synthesize angle;
@synthesize attributesDictionary;
@synthesize character;
@synthesize location;	

-(id)init {
	return [self initWithAngle:[NSNumber numberWithInt:0] attributes:NULL character:@"*" andPositionValue:[NSValue valueWithPoint:NSMakePoint(0, 0)]];
}

-(void)dealloc {
	[angle release];
	[character release];
	[location release];
	[attributesDictionary release];
	[super dealloc];
}

-(id)initWithCharacter:(TICharacter *)aCharacter {
	[self initWithAngle:[aCharacter angle] attributes:[aCharacter attributesDictionary] character:[aCharacter character] andPositionValue:[aCharacter location]];	
	return self;
}

-(id)initWithAngle:(NSNumber *)anAngle attributes:(NSDictionary *)theAttributes character:(NSString *)aCharacter andPositionValue:(NSValue *)aLocation {
	if(![super init]){
		return nil;
	}

	if(theAttributes == nil || aCharacter == nil || aLocation == nil){ 
		return nil;
	} else {
		[self setAngle:anAngle];
		[self setAttributesDictionary:[NSDictionary dictionaryWithDictionary:theAttributes]];
		[self setCharacter:[NSString stringWithString:aCharacter]];
		[self setLocation:aLocation];
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:angle forKey:@"angle"];
	[coder encodeObject:character forKey:@"character"];
	[coder encodePoint:[location pointValue]forKey:@"location"];
	[coder encodeObject:attributesDictionary forKey:@"attributesDictionary"];
}

-(id)initWithCoder:(NSCoder *)decoder {
	if(![super init]){
		return nil;
	}
	[self setAngle:[decoder decodeObjectForKey:@"angle"]];
	[self setCharacter:[decoder decodeObjectForKey:@"character"]];
	[self setLocation:[NSValue valueWithPoint:[decoder decodePointForKey:@"location"]]];
	[self setAttributesDictionary:[decoder decodeObjectForKey:@"attributesDictionary"]];
	return self;
}
	 
@end
