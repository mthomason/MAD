//
//  MADDocumentObjectDataReferenceAggregate.h
//  MAD
//
//  Created by Michael on 5/18/25.
//  Copyright © 2025 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADDocumentObjectDataReferenceAggregate_h
#define MAD_MADDocumentObjectDataReferenceAggregate_h

#import "MADDocumentObjectDataReference.h"

NS_ASSUME_NONNULL_BEGIN

@interface MADDocumentObjectDataReferenceAggregate : MADDocumentObjectDataReference

@property (nonatomic, copy, readonly) NSString *fieldKey;
@property (nonatomic, assign, readonly) int32_t groupNumber;
@property (nonatomic, assign, readonly) BOOL calculateInMemory;
@property (nonatomic, assign, readonly) MTAggregateGroupByType groupType;
@property (nonatomic, assign, readonly) MTAggregateFunctionType functionType;
- (NSString *)formattedStringForValue:(id)value;

@end

NS_ASSUME_NONNULL_END

#endif
