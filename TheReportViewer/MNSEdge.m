//
//  MNSEdge.m
//  TheReportViewer
//
//  Created by Michael Thomason on 3/14/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MNSEdge.h"

@implementation MNSEdge

@synthesize container = _container;
@synthesize leftVertex = _leftVertex, rightVertex = _rightVertex;

- (void)dealloc {
    [_container release];
    [_leftVertex release];
    [_rightVertex release];
    [super dealloc];
}

- (id)init {
    self = [super init];
    if (self) {
        
        NSObject *obj = [[NSObject alloc] init];
        [self setContainer: obj];
        [obj release];
        
        MNSVertex *leftVertext = [[MNSVertex alloc] init];
        [self setLeftVertex: leftVertext];
        [leftVertext release];
        
        MNSVertex *rightVertex = [[MNSVertex alloc] init];
        [self setLeftVertex: rightVertex];
        [rightVertex release];

    }
    return self;
}

- (id)initWithObject:(id)object leftVertex:(MNSVertex *)leftVertex andRightVertex:(MNSVertex *)rightVertex {
    self = [super init];
    if (self) {
        
        [self setContainer: [[object retain] autorelease]];
        [self setLeftVertex: [[leftVertex retain] autorelease]];
        [self setRightVertex: [[rightVertex retain] autorelease]];
 
    }
    return self;
}

@end