//
//  RptqQueryCache+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//  This file was automatically generated and should not be edited.
//

#ifndef Reports_RptqQueryCache_CoreDataProperties_h
#define Reports_RptqQueryCache_CoreDataProperties_h

#import "RptqQueryCache+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface RptqQueryCache (CoreDataProperties)

+ (NSFetchRequest<RptqQueryCache *> *)fetchRequest;

@property (nullable, nonatomic, retain) NSObject *cacheDate;
@property (nullable, nonatomic, retain) NSData *data;
@property (nullable, nonatomic, copy) NSString *filename;
@property (nullable, nonatomic, copy) NSNumber *identifier;
@property (nullable, nonatomic, retain) RptqQuery *hasQuery;

@end

NS_ASSUME_NONNULL_END

#endif
