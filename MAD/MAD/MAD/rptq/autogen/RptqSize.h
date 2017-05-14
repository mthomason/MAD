//
//  RptqSize+CoreDataClass.h
//  MAD
//
//  Created by Michael on 5/14/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqSize_h
#define MAD_RptqSize_h

#import <CoreData/NSManagedObject.h>
#import <CoreData/NSFetchRequest.h>

NS_ASSUME_NONNULL_BEGIN

@interface RptqSize : NSManagedObject

@end

@interface RptqSize (CoreDataProperties)

    + (NSFetchRequest<RptqSize *> *)fetchRequest;

    @property (nonatomic) float width;
    @property (nonatomic) float height;

@end

NS_ASSUME_NONNULL_END

#endif
