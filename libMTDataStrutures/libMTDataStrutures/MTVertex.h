//
//  MTVertex.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/10/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MTObject.h"
#import "MTProtocolLog.h"
#import "MTProtocolCompare.h"
#import "NSNumber+Extras.h"

typedef NS_ENUM(NSUInteger, MTAlgorithmColor) {
	MTColorBlack,
	MTColorWhite,
	MTColorGray
};

@class MTEdge;

@interface MTVertex : MTObject <MTProtocolCompare, MTProtocolLog>

- (id)init;
- (id)initWithID:(NSUInteger)idnumber;
- (id)initWithID:(NSUInteger)idnumber andObject:(id)object;

- (void)addEdge:(MTEdge *)edge;

- (NSUInteger)numberOfIncidentEdges;
- (NSArray *)incidentEdges;
- (void)removeEdge:(MTEdge *)edge;
- (BOOL)isAdjacentToVertex:(MTVertex *)vertex;

@property (assign) MTAlgorithmColor sortVertexColor;

@property (assign) MTAlgorithmColor bfsVertexColor;
@property (nonatomic, strong) MTVertex         *bfsPredecessor;
@property (nonatomic, strong) NSNumber         *bfsDistance;

@property (assign) MTAlgorithmColor dfsVertexColor;
@property (nonatomic, strong) NSNumber         *dfsDistance;
@property (nonatomic, strong) MTVertex         *dfsPredecessor;
@property (nonatomic, strong) NSNumber         *dfsFoundCounter;
@property (nonatomic, strong) NSNumber         *dfsTimestampDiscovered;
@property (nonatomic, strong) NSNumber         *dfsTimestampFinished;

@end