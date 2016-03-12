//
//  MTVertex.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/10/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_DataStructures_MTVertex_h
#define MAD_DataStructures_MTVertex_h

#import "MTObject.h"
#import "MTProtocolLog.h"
#import "MTProtocolCompare.h"

typedef NS_ENUM(NSUInteger, MTAlgorithmColor) {
	MTColorBlack,
	MTColorWhite,
	MTColorGray
};

@class MTEdge;

@interface MTVertex : MTObject <MTProtocolCompare, MTProtocolLog>

- (instancetype)init;
- (instancetype)initWithID:(NSUInteger)idnumber;
- (instancetype)initWithID:(NSUInteger)idnumber andObject:(id <NSCopying>)object NS_DESIGNATED_INITIALIZER;

- (void)addEdge:(MTEdge *)edge;

- (NSUInteger)numberOfIncidentEdges;
- (NSArray *)incidentEdges;
- (void)removeEdge:(MTEdge *)edge;
- (bool)isAdjacentToVertex:(MTVertex *)vertex;

@property (nonatomic, strong, readonly) NSNumber *uniqueIdForStructure;

@property (atomic, assign) MTAlgorithmColor sortVertexColor;
@property (atomic, assign) MTAlgorithmColor bfsVertexColor;
@property (atomic, assign) MTAlgorithmColor dfsVertexColor;

@property (nonatomic, weak)   MTVertex         *bfsPredecessor;
@property (nonatomic, strong) NSNumber         *bfsDistance;

@property (nonatomic, strong) NSNumber         *dfsDistance;
@property (nonatomic, weak)   MTVertex         *dfsPredecessor;
@property (nonatomic, strong) NSNumber         *dfsFoundCounter;
@property (nonatomic, strong) NSNumber         *dfsTimestampDiscovered;
@property (nonatomic, strong) NSNumber         *dfsTimestampFinished;

@end

#endif
