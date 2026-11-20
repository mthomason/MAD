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
#elif defined(__APPLE__)
@class UIImage;
typedef UIImage MADElementImage;
#else
// The store's Blob column already holds PNG bytes; off Apple those bytes are
// the type, with no UIKit to decode them into a picture (RptqDocumentElementImage
// (Extras) codes and decodes the picture where UIKit exists).
@class NSData;
typedef NSData MADElementImage;
#endif

NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentElementImage : RptqDocumentElement

@end

@interface RptqDocumentElementImage (CoreDataProperties)

@property (nullable, nonatomic, retain) MADElementImage *image;

@end

NS_ASSUME_NONNULL_END

#endif
