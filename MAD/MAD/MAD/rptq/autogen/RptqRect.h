//
//  RptqRect+CoreDataClass.h
//  MAD
//
//  Created by Michael on 5/14/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqRect_h
#define MAD_RptqRect_h

#import <CoreData/NSManagedObject.h>
#import <CoreData/NSFetchRequest.h>

@class RptqPoint, RptqSize;

NS_ASSUME_NONNULL_BEGIN

@interface RptqRect : NSManagedObject

@end

@interface RptqRect (CoreDataProperties)

    + (NSFetchRequest<RptqRect *> *)fetchRequest;

    @property (nullable, nonatomic, retain) RptqPoint *origin;
    @property (nullable, nonatomic, retain) RptqSize *size;

@end

NS_ASSUME_NONNULL_END

#endif
