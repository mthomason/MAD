//
//  RptqDirectionalProperty+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 5/14/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqDirectionalProperty+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface RptqDirectionalProperty (CoreDataProperties)

+ (NSFetchRequest<RptqDirectionalProperty *> *)fetchRequest;

@property (nonatomic) int16_t top;
@property (nonatomic) int16_t bottom;
@property (nonatomic) int16_t left;
@property (nonatomic) int16_t right;

@end

NS_ASSUME_NONNULL_END
