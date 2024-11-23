//
//  MTVertex.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/10/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_DataStructures_MTVertex_h
#define MAD_DataStructures_MTVertex_h

#import <MADDataStructures/MTObject.h>
#import <MADDataStructures/MTProtocolLog.h>
#import <MADDataStructures/MTProtocolCompare.h>

@class MTEdge, MADAlgorithmElementProperties, MADBfsProperties, MADDfsProperties, MADSortProperties;

typedef NS_ENUM(short, MADAlgorithmPropertyClass) {
	MADAlgorithmPropertyClassesDfs,
	MADAlgorithmPropertyClassesBfs,
	MADAlgorithmPropertyClassesSort
};

@interface MTVertex : NSObject
	<MTProtocolCompare, MTProtocolLog>

	@property (readonly, nonatomic, strong) id object;

	@property (nonatomic, assign, readonly) NSUInteger uniqueIdForStructure;
	@property (readonly) NSArray <MTEdge *> *incidentEdges;
	@property (readonly) NSUInteger numberOfIncidentEdges;

	@property (nonatomic, strong, readonly) MADAlgorithmElementProperties *properties;
	@property (nonatomic, strong, readonly) MADBfsProperties *bfsProperties;
	@property (nonatomic, strong, readonly) MADDfsProperties *dfsProperties;
	@property (nonatomic, strong, readonly) MADSortProperties *sortProperties;

	- (instancetype)init;
	- (instancetype)initWithID:(NSUInteger)idnumber;
	- (instancetype)initWithID:(NSUInteger)idnumber andObject:(id <NSCopying>)object NS_DESIGNATED_INITIALIZER;

	- (void)addEdge:(MTEdge *)edge;

	- (void)removeEdge:(MTEdge *)edge;
	- (BOOL)isAdjacentToVertex:(MTVertex *)vertex;

@end

#endif
