//
//  MTGraph+RptqQuery.h
//  MAD Designer
//
//  Created by Michael Thomason on 9/3/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MTGraph_RptqQuery_h
#define MAD_Designer_MTGraph_RptqQuery_h

#import <MADDataStructures/MTGraph.h>

@class RptqQuery;
@class MADModelQuery;
@class NSManagedObjectID;
@class NSManagedObjectContext;

@interface MTGraph (RptqQuery)

    - (instancetype)initWithQuery:(RptqQuery *)query;
    - (instancetype)initWtthQueryID:(MADModelQuery *)query;
    - (instancetype)initWithQueryID:(NSManagedObjectID *)queryID
               managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end

#endif
