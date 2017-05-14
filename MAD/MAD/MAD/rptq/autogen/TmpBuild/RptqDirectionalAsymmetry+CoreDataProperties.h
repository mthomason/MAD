//
//  RptqDirectionalAsymmetry+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 5/14/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqDirectionalAsymmetry+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface RptqDirectionalAsymmetry (CoreDataProperties)

+ (NSFetchRequest<RptqDirectionalAsymmetry *> *)fetchRequest;

@property (nonatomic) float top;
@property (nonatomic) float bottom;
@property (nonatomic) float left;
@property (nonatomic) float right;

@end

NS_ASSUME_NONNULL_END
