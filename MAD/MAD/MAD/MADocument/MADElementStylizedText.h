//
//  MADocumentObjectTextAttributes.h
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MAD_MADocumentObjectAttributesText_h
#define Reports_MAD_MADocumentObjectAttributesText_h

#import <Foundation/NSObject.h>
#import <MAD/MADAlignment.h>

@class UIFontDescriptor;
@class RptqDocumentElement;
@class NSString;
@class NSNumber;

@interface MADElementStylizedText : NSObject

    - (nullable instancetype)initWithFontName:(NSString * _Nullable) fontname
                                     fontSize:(double) fontsize
                                         bold:(BOOL)bold
                                       italic:(BOOL)italic
                                    underline:(BOOL)underline
                                       strike:(BOOL)strike
                          horizontalAlignment:(MADHorizontalAlignment)horizontalAlignment
                                                                    NS_DESIGNATED_INITIALIZER;

    @property (nonnull, nonatomic, strong, readonly) NSDictionary        *fontAttributes;

@end

#endif
