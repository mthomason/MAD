//
//  RptqDocumentElementGroupKey+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqDocumentElementGroupKey_CoreDataProperties_h
#define MAD_RptqDocumentElementGroupKey_CoreDataProperties_h

#import "RptqDocumentElementGroupKey+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentElementGroupKey (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentElementGroupKey *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *groupNumber;

@end

NS_ASSUME_NONNULL_END

#endif
