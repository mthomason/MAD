//
//  RptqDocumentElementImage.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_RptqDocumentElementImage_h
#define MAD_RptqDocumentElementImage_h

#include <TargetConditionals.h>
#import <MAD/RptqDocumentElement.h>

#if defined(__APPLE__) && TARGET_OS_OSX
@class NSImage;
typedef NSImage MADElementImage;
#else
@class UIImage;
typedef UIImage MADElementImage;
#endif

NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentElementImage : RptqDocumentElement

@end

@interface RptqDocumentElementImage (CoreDataProperties)

@property (nullable, nonatomic, retain) MADElementImage *image;

@end

NS_ASSUME_NONNULL_END

#endif
