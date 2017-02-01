//
//  RptqDocumentElementGroupKey+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqDocumentElementGroupKey_CoreDataProperties_h
#define MAD_RptqDocumentElementGroupKey_CoreDataProperties_h

#import "RptqDocumentElementGroupKey.h"
#import <CoreData/NSFetchRequest.h>

NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentElementGroupKey (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentElementGroupKey *> *)fetchRequest;

@property (nonatomic) int16_t groupNumber;

@end

NS_ASSUME_NONNULL_END

#endif
