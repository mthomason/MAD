//
//  RptqQuerySort+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqQuerySort+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface RptqQuerySort (CoreDataProperties)

+ (NSFetchRequest<RptqQuerySort *> *)fetchRequest;

@property (nonatomic) BOOL ascending;
@property (nullable, nonatomic, copy) NSString *fields;
@property (nonatomic) int64_t identifier;
@property (nullable, nonatomic, retain) RptqQueryField *hasField;
@property (nullable, nonatomic, retain) RptqQuery *inQuery;

@end

NS_ASSUME_NONNULL_END
