//
//  RptqQueryCache+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqQueryCache_CoreDataProperties_h
#define MAD_RptqQueryCache_CoreDataProperties_h

#import "RptqQueryCache.h"
#import <CoreData/NSFetchRequest.h>

NS_ASSUME_NONNULL_BEGIN

@interface RptqQueryCache (CoreDataProperties)

+ (NSFetchRequest<RptqQueryCache *> *)fetchRequest;

@property (nullable, nonatomic, retain) NSObject *cacheDate;
@property (nullable, nonatomic, retain) NSData *data;
@property (nullable, nonatomic, copy) NSString *filename;
@property (nonatomic) int64_t identifier;
@property (nullable, nonatomic, retain) RptqQuery *hasQuery;

@end

NS_ASSUME_NONNULL_END

#endif
