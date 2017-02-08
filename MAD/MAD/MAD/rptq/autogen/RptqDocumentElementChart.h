//
//  RptqDocumentElementChart.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqDocumentElementChart_RptqDocumentElement_h
#define MAD_RptqDocumentElementChart_RptqDocumentElement_h

#import "RptqDocumentElement.h"

NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentElementChart : RptqDocumentElement

@end

@interface RptqDocumentElementChart (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentElementChart *> *)fetchRequest;

@end

NS_ASSUME_NONNULL_END

#endif
