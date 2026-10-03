//
//  RptqDocumentElementGroupKey.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_RptqDocumentElementGroupKey_RptqDocumentElement_h
#define MAD_RptqDocumentElementGroupKey_RptqDocumentElement_h

#import "RptqDocumentElement.h"
NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentElementGroupKey : RptqDocumentElement

@end

@interface RptqDocumentElementGroupKey (CoreDataProperties)

@property (nonatomic) int16_t groupNumber;

@end

NS_ASSUME_NONNULL_END

#endif
