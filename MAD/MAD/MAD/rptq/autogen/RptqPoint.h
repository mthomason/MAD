//
//  RptqPoint+CoreDataClass.h
//  MAD
//
//  Created by Michael on 5/14/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqPoint_h
#define MAD_RptqPoint_h

#import <CoreData/NSManagedObject.h>
#import <CoreData/NSFetchRequest.h>

NS_ASSUME_NONNULL_BEGIN

@class RptqDocumentElement, RptqRect;

@interface RptqPoint : NSManagedObject

@end

@interface RptqPoint (CoreDataProperties)

    + (NSFetchRequest<RptqPoint *> *)fetchRequest;

    @property (nonatomic) float x;
    @property (nonatomic) float y;
    @property (nullable, nonatomic, retain) RptqDocumentElement *inElement;
    @property (nullable, nonatomic, retain) RptqRect *inRect;

@end

NS_ASSUME_NONNULL_END

#endif
