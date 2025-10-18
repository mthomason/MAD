//
//  MADDocumentObjectDataReferenceLabelDynamic.h
//  MAD
//
//  Created by Michael on 5/18/25.
//  Copyright © 2025 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADDocumentObjectDataReferenceLabelDynamic_h
#define MAD_MADDocumentObjectDataReferenceLabelDynamic_h

#import "MADDocumentObjectDataReference.h"

NS_ASSUME_NONNULL_BEGIN

@interface MADDocumentObjectDataReferenceLabelDynamic : MADDocumentObjectDataReference

@property (nonatomic, copy, readonly) NSString *fieldKey;
- (NSString *)formattedStringForValue:(id)value;

@end

NS_ASSUME_NONNULL_END

#endif
