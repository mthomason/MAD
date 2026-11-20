//
//  RptqDocumentElementImage+Extras.h
//  Reports
//
//  Created by Michael Thomason on 3/17/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_RptqDocumentElementImage_Extras_h
#define Reports_RptqDocumentElementImage_Extras_h

#import <MAD/RptqDocumentElementImage.h>

NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentElementImage (Extras)

/// The element's picture in the store's wire format -- PNG bytes.  Off Apple the
/// picture *is* those bytes; where UIKit/AppKit exists they are decoded back into
/// the picture the designers draw, and encoded again on the way in, so the column
/// is always PNG no matter which platform wrote it.
- (nullable NSData *)pngData;
- (void)setPngData:(nullable NSData *)pngData;

@end

NS_ASSUME_NONNULL_END

#endif
