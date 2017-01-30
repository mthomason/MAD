//
//  RptqQueryGroup+CoreDataClass.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqQueryGroup_NSManagedObject_h
#define MAD_RptqQueryGroup_NSManagedObject_h

#import <CoreData/NSManagedObject.h>

@class RptqDocumentSection, RptqQuery, RptqQueryField;

NS_ASSUME_NONNULL_BEGIN

@interface RptqQueryGroup : NSManagedObject

@end

NS_ASSUME_NONNULL_END

#import "RptqQueryGroup+CoreDataProperties.h"

#endif
