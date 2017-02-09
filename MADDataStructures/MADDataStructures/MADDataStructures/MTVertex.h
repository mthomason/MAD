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

@class MTEdge, MADAlgorithmElementProperties, MADBfsProperties, MADDfsProperties, MADSortProperties;

typedef NS_ENUM(short, MADAlgorithmPropertyClass) {
    MADAlgorithmPropertyClassesDfs,
    MADAlgorithmPropertyClassesBfs,
    MADAlgorithmPropertyClassesSort
};

@interface MTVertex : NSObject
    <MTProtocolCompare,
        MTProtocolLog>

    @property (readonly, nonatomic, strong) id object;

    - (instancetype)init;
    - (instancetype)initWithID:(NSUInteger)idnumber;
    - (instancetype)initWithID:(NSUInteger)idnumber andObject:(id <NSCopying>)object NS_DESIGNATED_INITIALIZER;

    @property (nonatomic, assign, readonly) NSUInteger uniqueIdForStructure;
    @property (readonly) NSArray <MTEdge *> *incidentEdges;
    @property (readonly) NSUInteger numberOfIncidentEdges;

    - (void)addEdge:(MTEdge *)edge;

    - (void)removeEdge:(MTEdge *)edge;
    - (BOOL)isAdjacentToVertex:(MTVertex *)vertex;

    @property (nonatomic, strong, readonly) MADAlgorithmElementProperties *properties;
    @property (nonatomic, strong, readonly) MADBfsProperties *bfsProperties;
    @property (nonatomic, strong, readonly) MADDfsProperties *dfsProperties;
    @property (nonatomic, strong, readonly) MADSortProperties *sortProperties;

@end

#endif
