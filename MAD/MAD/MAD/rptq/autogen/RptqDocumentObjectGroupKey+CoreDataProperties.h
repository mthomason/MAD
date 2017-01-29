//
//  RptqDocumentObjectGroupKey+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//  This file was automatically generated and should not be edited.
//

#import "RptqDocumentObjectGroupKey+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentObjectGroupKey (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentObjectGroupKey *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *groupNumber;
@property (nullable, nonatomic, retain) RptqDocumentObject *parentObject;

@end

NS_ASSUME_NONNULL_END
