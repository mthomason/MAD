//
//  MADDocumentObjectDataReferenceImage.h
//  MAD
//
//  Created by Michael on 5/18/25.
//  Copyright © 2025 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADDocumentObjectDataReferenceImage_h
#define MAD_MADDocumentObjectDataReferenceImage_h

#import "MADDocumentObjectDataReference.h"

NS_ASSUME_NONNULL_BEGIN

@interface MADDocumentObjectDataReferenceImage : MADDocumentObjectDataReference

@property (nullable, nonatomic, copy, readonly) UIImage *image;

@end

NS_ASSUME_NONNULL_END

#endif
