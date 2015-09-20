//
//  MADQueryVisualizationCacheData.h
//  MAD Designer
//
//  Created by Michael Thomason on 9/5/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MADQueryVisualizationTableDefination;

@interface MADQueryVisualizationCacheData : NSObject
    <NSCoding>

@property (nonatomic, assign) CGPoint scrollViewContentOffset;
@property (nonatomic, assign) CGFloat scrollViewZoomScale;

- (void)addTableDefination:(MADQueryVisualizationTableDefination *)tableDef forObjectID:(NSManagedObjectID *)objectID;
- (MADQueryVisualizationTableDefination *)tableDefinationForObjectID:(NSManagedObjectID *)objectID;

@end
