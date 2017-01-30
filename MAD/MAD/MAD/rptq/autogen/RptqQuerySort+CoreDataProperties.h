//
//  RptqQuerySort+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqQuerySort_CoreDataProperties_h
#define MAD_RptqQuerySort_CoreDataProperties_h

#import "RptqQuerySort+CoreDataClass.h"
#import <CoreData/NSFetchRequest.h>

NS_ASSUME_NONNULL_BEGIN

@interface RptqQuerySort (CoreDataProperties)

+ (NSFetchRequest<RptqQuerySort *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *ascending;
@property (nullable, nonatomic, copy) NSString *fields;
@property (nullable, nonatomic, copy) NSNumber *identifier;
@property (nullable, nonatomic, retain) RptqQueryField *hasField;
@property (nullable, nonatomic, retain) RptqQuery *inQuery;

@end

NS_ASSUME_NONNULL_END

#endif
