//
//  RptqDocumentSection.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqDocumentSection_NSManagedObject_h
#define MAD_RptqDocumentSection_NSManagedObject_h

#import <CoreData/NSManagedObject.h>

@class RptqDocument, RptqDocumentSectionRows, RptqQueryGroup;

NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentSection : NSManagedObject

@end

NS_ASSUME_NONNULL_END

#import "RptqDocumentSection+CoreDataProperties.h"

#endif
