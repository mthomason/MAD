//
//  RptqAlignment+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 5/14/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqAlignment+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface RptqAlignment (CoreDataProperties)

+ (NSFetchRequest<RptqAlignment *> *)fetchRequest;

@property (nonatomic) int16_t horizontal;
@property (nonatomic) int16_t vertical;

@end

NS_ASSUME_NONNULL_END
