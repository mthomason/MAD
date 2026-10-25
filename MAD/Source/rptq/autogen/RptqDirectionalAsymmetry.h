//
//  RptqDirectionalAsymmetry+CoreDataClass.h
//  MAD
//
//  Created by Michael on 5/14/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_RptqDirectionalAsymmetry_h
#define MAD_RptqDirectionalAsymmetry_h

#import <MAD/RptqObject.h>

@class RptqDocumentElement, RptqBorder;

NS_ASSUME_NONNULL_BEGIN

@interface RptqDirectionalAsymmetry : RptqObject

@end

@interface RptqDirectionalAsymmetry (CoreDataProperties)

@property (nonatomic) float top;
@property (nonatomic) float bottom;
@property (nonatomic) float left;
@property (nonatomic) float right;
@property (nullable, nonatomic, retain) RptqDocumentElement *inElementMargin;
@property (nullable, nonatomic, retain) RptqDocumentElement *inElementPadding;
@property (nullable, nonatomic, retain) RptqBorder *inBorder;

@end

NS_ASSUME_NONNULL_END

#endif
