//
//  MTActiveDocument.m
//  Reports
//
//  Created by Michael Thomason on 3/12/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTActiveDocument.h"

@interface MTActiveDocument ()

@property (nonatomic, retain) id document;

@end

@implementation MTActiveDocument

static MTActiveDocument *sharedSingleton = nil;

+ (void)initialize {
    static BOOL initialized = NO;
    if (initialized == NO) {
        initialized = YES;
        if (sharedSingleton == nil) {
            sharedSingleton = [[super allocWithZone:NULL] init];
            [sharedSingleton setDocument:nil];
        }
    }
}

+ (MTActiveDocument *)sharedDocument {
    return sharedSingleton;
}

+ (id)allocWithZone:(NSZone *)zone {
    //Leaks because of singleton... fine.
    return [[self sharedDocument] retain];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id)retain {
    return self;
}

- (NSUInteger)retainCount {
    return NSUIntegerMax;
}

- (oneway void)release { }

- (id)autorelease {
    return self;
}

- (void)setActiveDocument:(id)document {
    @synchronized(self) {
        if (document != [self document]) {
            id activeDocument = [document retain];
            [self setDocument:activeDocument];
            [activeDocument release];
        }
    }
}

- (id)activeDocument {
    return [[[self document] retain] autorelease];
}

@end
