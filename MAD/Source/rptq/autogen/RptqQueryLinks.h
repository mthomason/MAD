//
//  RptqQueryLinks.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_RptqQueryLinks_NSManagedObject_h
#define MAD_RptqQueryLinks_NSManagedObject_h

#import <MAD/RptqObject.h>

@class RptqQuery, RptqQueryField;

NS_ASSUME_NONNULL_BEGIN

@interface RptqQueryLinks : RptqObject

@end

@interface RptqQueryLinks (CoreDataProperties)

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
