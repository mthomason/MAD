//
//  MTPair.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/10/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTPair.h"
#import "MTObject.h"

@interface MTPair ()

@end

@implementation MTPair

- (void)dealloc {
    [_former release];
    [_latter release];
    [super dealloc];
}

- (id)init {
    return [self initWithFormer:nil andLatter:nil];
}

- (id)initWithFormer:(id)former andLatter:(id)latter {
    self = [super init];
    if (self) {

        id f = [former retain];
        [self setFormer:f];
        [f release];
        
        id l = [latter retain];
        [self setLatter:l];
        [latter release];
        
    }
    return self;
}

+ (id)pairWithFormer:(id)former andLatter:(id)latter {
    MTPair *pair = [[MTPair alloc] initWithFormer:former andLatter:latter];
    return [pair autorelease];
}

@end