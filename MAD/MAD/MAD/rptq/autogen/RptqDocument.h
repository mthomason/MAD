//
//  RptqDocument.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqDocument_h
#define MAD_RptqDocument_h

#import <CoreData/NSManagedObject.h>

@class RptqDatabase, RptqDocumentSection;

NS_ASSUME_NONNULL_BEGIN

@interface RptqDocument : NSManagedObject

@end

NS_ASSUME_NONNULL_END

#import "RptqDocument+CoreDataProperties.h"

#endif
