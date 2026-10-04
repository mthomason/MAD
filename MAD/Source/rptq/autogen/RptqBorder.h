//
//  RptqBorder+CoreDataClass.h
//  MAD
//
//  Created by Michael on 5/14/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_RptqBorder_h
#define MAD_RptqBorder_h

#import <MAD/RptqObject.h>

@class RptqDirectionalAsymmetry, RptqDirectionalProperty, RptqDocumentElement;

NS_ASSUME_NONNULL_BEGIN

@interface RptqBorder : RptqObject

@end

@interface RptqBorder (CoreDataProperties)

    @property (nullable, nonatomic, retain) RptqDirectionalAsymmetry *width;
    @property (nullable, nonatomic, retain) RptqDirectionalProperty *style;
    @property (nullable, nonatomic, retain) RptqDocumentElement *inElement;

@end

NS_ASSUME_NONNULL_END

#endif
