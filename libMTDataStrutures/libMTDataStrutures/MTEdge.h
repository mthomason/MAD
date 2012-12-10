//
//  MTEdge.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/10/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MTVertex;

@interface MTEdge : NSObject

@property(readonly) BOOL isDirected;

- (id)initWithOrigin:(MTVertex *)origin andDestination:(MTVertex *)destination;
- (id)initWithOrigin:(MTVertex *)origin destination:(MTVertex *)destination andObject:(id)object;
- (id)initWithOrigin:(MTVertex *)origin destination:(MTVertex *)destination object:(id)object andWeight:(NSNumber *)weight;

- (MTVertex *)origin;
- (MTVertex *)destination;

@end