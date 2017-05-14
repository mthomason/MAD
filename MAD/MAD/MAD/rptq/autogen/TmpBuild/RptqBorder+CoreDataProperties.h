//
//  RptqBorder+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 5/14/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqBorder+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface RptqBorder (CoreDataProperties)

+ (NSFetchRequest<RptqBorder *> *)fetchRequest;

@property (nullable, nonatomic, retain) RptqDirectionalAsymmetry *width;
@property (nullable, nonatomic, retain) RptqDirectionalProperty *style;

@end

NS_ASSUME_NONNULL_END
