//
//  RptqQuerySort+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MAD.RptqQuerySort+CoreDataClass.h"


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
