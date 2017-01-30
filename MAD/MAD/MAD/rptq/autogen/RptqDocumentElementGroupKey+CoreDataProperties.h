//
//  RptqDocumentElementGroupKey+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentElementGroupKey+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentElementGroupKey (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentElementGroupKey *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *groupNumber;

@end

NS_ASSUME_NONNULL_END
