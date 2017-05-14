//
//  RptqDirectionalProperty+CoreDataClass.h
//  MAD
//
//  Created by Michael on 5/14/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqDirectionalProperty_h
#define MAD_RptqDirectionalProperty_h

#import <CoreData/NSManagedObject.h>
#import <CoreData/NSFetchRequest.h>

NS_ASSUME_NONNULL_BEGIN

@interface RptqDirectionalProperty : NSManagedObject

@end

@interface RptqDirectionalProperty (CoreDataProperties)

+ (NSFetchRequest<RptqDirectionalProperty *> *)fetchRequest;

@property (nonatomic) int16_t top;
@property (nonatomic) int16_t bottom;
@property (nonatomic) int16_t left;
@property (nonatomic) int16_t right;

@end

NS_ASSUME_NONNULL_END

#endif
