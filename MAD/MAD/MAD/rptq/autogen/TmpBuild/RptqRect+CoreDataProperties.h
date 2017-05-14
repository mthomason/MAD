//
//  RptqRect+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 5/14/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqRect+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface RptqRect (CoreDataProperties)

+ (NSFetchRequest<RptqRect *> *)fetchRequest;

@property (nullable, nonatomic, retain) RptqPoint *origin;
@property (nullable, nonatomic, retain) RptqSize *size;

@end

NS_ASSUME_NONNULL_END
