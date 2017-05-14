//
//  RptqSize+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 5/14/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqSize+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface RptqSize (CoreDataProperties)

+ (NSFetchRequest<RptqSize *> *)fetchRequest;

@property (nonatomic) float width;
@property (nonatomic) float height;

@end

NS_ASSUME_NONNULL_END
