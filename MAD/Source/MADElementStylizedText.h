//
//  MADocumentObjectTextAttributes.h
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MAD_MADocumentObjectAttributesText_h
#define Reports_MAD_MADocumentObjectAttributesText_h

#import <Foundation/NSObject.h>
#import <MAD/MADAlignment.h>

@class RptqTextStyle, NSString;


@interface MADElementStylizedText : NSObject

@property (nonnull, nonatomic, strong, readonly) NSDictionary        *fontAttributes;
- (nullable instancetype)initWithFontName:(NSString * _Nullable) fontname
								 fontSize:(double) fontsize
								textStyle:(RptqTextStyle  * _Nullable )textStyle
					  horizontalAlignment:(MADHorizontalAlignment)horizontalAlignment NS_DESIGNATED_INITIALIZER;


@end

#endif
