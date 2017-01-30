//
//  RptqDocumentElementImage+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqDocumentElementImage_CoreDataProperties_h
#define MAD_RptqDocumentElementImage_CoreDataProperties_h

#import "RptqDocumentElementImage+CoreDataClass.h"

NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentElementImage (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentElementImage *> *)fetchRequest;

@property (nullable, nonatomic, retain) UIImage *image;

@end

NS_ASSUME_NONNULL_END

#endif
