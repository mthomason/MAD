//
//  MADQueryVisulizationDefination.h
//  MAD Designer
//
//  Created by Michael Thomason on 9/3/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MAD/MAD.h>
#import <MADDataStructures/MADDataStructures.h>

@class RptqQuery, MTGraph, MTLinkedList;

@interface MADQueryVisualizationDefination : NSObject

- (instancetype)initWithQuery:(RptqQuery *)query;

@property (nonatomic, strong, readonly) MTGraph *graphRepresentation;
@property (nonatomic, strong, readonly) MTLinkedList *topologicallySortedTables;
@property (nonatomic, strong, readonly) NSArray *startingPoints;
@property (nonatomic, assign, readonly, getter=isDirectedAcyclicGraph) BOOL directedAcyclicGraph;

@end
