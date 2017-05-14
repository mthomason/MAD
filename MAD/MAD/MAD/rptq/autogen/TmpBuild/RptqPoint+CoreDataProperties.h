//
//  RptqPoint+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 5/14/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqPoint+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface RptqPoint (CoreDataProperties)

+ (NSFetchRequest<RptqPoint *> *)fetchRequest;

@property (nonatomic) float x;
@property (nonatomic) float y;

@end

NS_ASSUME_NONNULL_END
