//
//  RptqNumericFormat+CoreDataClass.h
//  MAD
//
//  Created by Michael on 5/14/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqNumericFormat_h
#define MAD_RptqNumericFormat_h

#import <CoreData/NSManagedObject.h>
#import <CoreData/NSFetchRequest.h>

@class NSLocale, RptqDocumentElement;

NS_ASSUME_NONNULL_BEGIN

@interface RptqNumericFormat : NSManagedObject

@end

@interface RptqNumericFormat (CoreDataProperties)

+ (NSFetchRequest<RptqNumericFormat *> *)fetchRequest;

@property (nullable, nonatomic, retain) NSLocale *locale;
@property (nonatomic) BOOL enabled;
@property (nonatomic) int64_t decimalCount;
@property (nullable, nonatomic, retain) RptqDocumentElement *inElement;

@end

NS_ASSUME_NONNULL_END

#endif
