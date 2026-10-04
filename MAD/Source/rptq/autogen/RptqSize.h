//
//  RptqSize+CoreDataClass.h
//  MAD
//
//  Created by Michael on 5/14/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_RptqSize_h
#define MAD_RptqSize_h

#import <MAD/RptqObject.h>

NS_ASSUME_NONNULL_BEGIN

@class RptqRect;

@interface RptqSize : RptqObject

@end

@interface RptqSize (CoreDataProperties)

        @property (nonatomic) float width;
    @property (nonatomic) float height;
    @property (nullable, nonatomic, retain) RptqRect *inRect;

@end

NS_ASSUME_NONNULL_END

#endif
