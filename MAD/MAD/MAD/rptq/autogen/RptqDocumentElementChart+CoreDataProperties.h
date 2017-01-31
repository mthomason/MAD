//
//  RptqDocumentElementChart+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqDocumentElementChart_CoreDataProperties_h
#define MAD_RptqDocumentElementChart_CoreDataProperties_h

#import "RptqDocumentElementChart+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentElementChart (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentElementChart *> *)fetchRequest;


@end

NS_ASSUME_NONNULL_END

#endif
