//
//  MNSGraph.h
//  TheReportViewer
//
//  Created by Michael Thomason on 3/14/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MNSGraph : NSObject

@property (retain) NSSet *vertices;

- (id)initWithVertices:(NSSet *)vertices;

@end