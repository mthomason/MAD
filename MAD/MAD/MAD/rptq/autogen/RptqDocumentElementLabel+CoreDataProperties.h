//
//  RptqDocumentElementLabel+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqDocumentElementLabel_CoreDataProperties_h
#define MAD_RptqDocumentElementLabel_CoreDataProperties_h

#import "RptqDocumentElementLabel+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentElementLabel (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentElementLabel *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *text;

@end

NS_ASSUME_NONNULL_END

#endif
