//
//  RptqDocumentElementImage.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_RptqDocumentElementImage_h
#define MAD_RptqDocumentElementImage_h

#import "RptqDocumentElement.h"

@class UIImage;

NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentElementImage : RptqDocumentElement

@end

@interface RptqDocumentElementImage (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentElementImage *> *)fetchRequest;

@property (nullable, nonatomic, retain) UIImage *image;

@end

NS_ASSUME_NONNULL_END

#endif
