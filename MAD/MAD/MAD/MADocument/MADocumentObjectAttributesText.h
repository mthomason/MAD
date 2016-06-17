//
//  MADocumentObjectTextAttributes.h
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MAD_MADocumentObjectAttributesText_h
#define Reports_MAD_MADocumentObjectAttributesText_h

#import "MADocumentObjectAttributes.h"

@class UIFontDescriptor;

@interface MADocumentObjectAttributesText : MADocumentObjectAttributes

    - (nullable instancetype)initWithObject:(RptqDocumentObject * _Nonnull)object
                          andFontDescriptor:(UIFontDescriptor * _Nullable)fontDescriptor
                                                                    NS_DESIGNATED_INITIALIZER;

    @property (nonnull, nonatomic, strong, readonly) UIFontDescriptor    *fontDescriptor;
    @property (nonnull, nonatomic, strong, readonly) NSDictionary        *fontAttributes;

@end

#endif
