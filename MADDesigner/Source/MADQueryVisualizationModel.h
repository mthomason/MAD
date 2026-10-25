//
//  MADQueryVisulizationDefination.h
//  MAD Designer
//
//  Created by Michael Thomason on 9/3/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_Designer_MADQueryVisualizationDefination_h
#define MAD_Designer_MADQueryVisualizationDefination_h

#import <Foundation/NSObject.h>

@class MADModelQuery, MTGraph, MTLinkedList, NSArray<__covariant ObjectType>;

@interface MADQueryVisualizationModel : NSObject

@property (nonatomic, strong, readonly) MTGraph *graphRepresentation;
@property (nonatomic, strong, readonly) MTLinkedList *topologicallySortedTables;
@property (nonatomic, strong, readonly) NSArray <NSNumber *> *startingPoints;
@property (nonatomic, assign, readonly, getter=isDirectedAcyclicGraph) BOOL directedAcyclicGraph;

- (instancetype)initWithQuery:(MADModelQuery *)query;
- (BOOL)isTopLevel:(NSNumber *)identifier;

@end

#endif
