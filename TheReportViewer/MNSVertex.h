//
//  MNSVertex.h
//  TheReportViewer
//
//  Created by Michael Thomason on 3/14/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MNSVertex : NSObject

@property (retain) id container;
@property (retain) NSSet *linkedEdges;

- (id)initWithObject:(id)object withEdges:(NSSet *)edges;

@end