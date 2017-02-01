//
//  RptqQueryLinks+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqQueryLinks_CoreDataProperties_h
#define MAD_RptqQueryLinks_CoreDataProperties_h

#import "RptqQueryLinks.h"
#import <CoreData/NSFetchRequest.h>

NS_ASSUME_NONNULL_BEGIN

@interface RptqQueryLinks (CoreDataProperties)

+ (NSFetchRequest<RptqQueryLinks *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *fieldLeftID;
@property (nullable, nonatomic, copy) NSString *fieldRightID;
@property (nonatomic) int64_t identifier;
@property (nonatomic) int16_t type;
@property (nullable, nonatomic, copy) NSString *tableLeftID;
@property (nullable, nonatomic, copy) NSString *tableRightID;
@property (nullable, nonatomic, retain) RptqQueryField *hasLeftField;
@property (nullable, nonatomic, retain) RptqQueryField *hasRightField;
@property (nullable, nonatomic, retain) RptqQuery *inQuery;

@end

NS_ASSUME_NONNULL_END

#endif
