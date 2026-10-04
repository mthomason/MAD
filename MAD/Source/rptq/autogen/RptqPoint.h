//
//  RptqPoint+CoreDataClass.h
//  MAD
//
//  Created by Michael on 5/14/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_RptqPoint_h
#define MAD_RptqPoint_h

#import <MAD/RptqObject.h>

NS_ASSUME_NONNULL_BEGIN

@class RptqDocumentElement, RptqRect;

@interface RptqPoint : RptqObject

@end

@interface RptqPoint (CoreDataProperties)

        @property (nonatomic) float x;
    @property (nonatomic) float y;
    @property (nullable, nonatomic, retain) RptqDocumentElement *inElement;
    @property (nullable, nonatomic, retain) RptqRect *inRect;

@end

NS_ASSUME_NONNULL_END

#endif
