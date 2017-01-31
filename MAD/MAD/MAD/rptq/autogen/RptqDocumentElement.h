//
//  RptqDocumentElement.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqDocumentElement_NSManagedObject_h
#define MAD_RptqDocumentElement_NSManagedObject_h

#import <CoreData/NSManagedObject.h>

@class NSObject, RptqDocumentSectionRows;

NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentElement : NSManagedObject

@end

NS_ASSUME_NONNULL_END

#import "RptqDocumentElement+CoreDataProperties.h"

#endif
