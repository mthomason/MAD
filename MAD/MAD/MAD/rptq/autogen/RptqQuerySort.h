//
//  RptqQuerySort.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqQuerySort_NSManagedObject_h
#define MAD_RptqQuerySort_NSManagedObject_h

#import <CoreData/NSManagedObject.h>
#import <CoreData/NSFetchRequest.h>

@class RptqQuery, RptqQueryField;

NS_ASSUME_NONNULL_BEGIN

@interface RptqQuerySort : NSManagedObject

@end

@interface RptqQuerySort (CoreDataProperties)

+ (NSFetchRequest<RptqQuerySort *> *)fetchRequest;

@property (nonatomic) int64_t identifier;
@property (nonatomic) BOOL ascending;
@property (nullable, nonatomic, retain) RptqQueryField *hasField;
@property (nullable, nonatomic, retain) RptqQuery *inQuery;

@end

NS_ASSUME_NONNULL_END

#endif
