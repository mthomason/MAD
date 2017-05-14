//
//  RptqNumericFormat+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 5/14/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqNumericFormat+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface RptqNumericFormat (CoreDataProperties)

+ (NSFetchRequest<RptqNumericFormat *> *)fetchRequest;

@property (nullable, nonatomic, retain) NSLocale *locale;
@property (nonatomic) BOOL enabled;
@property (nonatomic) int64_t decimalCount;

@end

NS_ASSUME_NONNULL_END
