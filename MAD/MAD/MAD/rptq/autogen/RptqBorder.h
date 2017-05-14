//
//  RptqBorder+CoreDataClass.h
//  MAD
//
//  Created by Michael on 5/14/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqBorder_h
#define MAD_RptqBorder_h

#import <CoreData/NSManagedObject.h>
#import <CoreData/NSFetchRequest.h>

@class RptqDirectionalAsymmetry, RptqDirectionalProperty;

NS_ASSUME_NONNULL_BEGIN

@interface RptqBorder : NSManagedObject

@end

@interface RptqBorder (CoreDataProperties)

+ (NSFetchRequest<RptqBorder *> *)fetchRequest;

@property (nullable, nonatomic, retain) RptqDirectionalAsymmetry *width;
@property (nullable, nonatomic, retain) RptqDirectionalProperty *style;

@end

NS_ASSUME_NONNULL_END

#endif
