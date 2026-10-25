//
//  RptqDocumentElementImage.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_RptqDocumentElementImage_h
#define MAD_RptqDocumentElementImage_h

#import <MAD/RptqDocumentElement.h>

@class UIImage;

NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentElementImage : RptqDocumentElement

@end

@interface RptqDocumentElementImage (CoreDataProperties)

@property (nullable, nonatomic, retain) UIImage *image;

@end

NS_ASSUME_NONNULL_END

#endif
