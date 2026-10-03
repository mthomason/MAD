//
//  RptqAlignment+CoreDataClass.h
//  MAD
//
//  Created by Michael on 5/14/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_RptqAlignment_h
#define MAD_RptqAlignment_h

#import "RptqObject.h"

NS_ASSUME_NONNULL_BEGIN

@class RptqDocumentElement;

@interface RptqAlignment : RptqObject

@end

@interface RptqAlignment (CoreDataProperties)

@property (nonatomic) int16_t horizontal;
@property (nonatomic) int16_t vertical;
@property (nullable, nonatomic, retain) RptqDocumentElement *inElement;

@end

NS_ASSUME_NONNULL_END

#endif
