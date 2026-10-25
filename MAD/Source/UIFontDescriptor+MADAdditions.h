//
//  MADFontDescriptor
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MAD_UIFontDescriptor__DocumentObject_h
#define Reports_MAD_UIFontDescriptor__DocumentObject_h

#import <UIKit/UIFontDescriptor.h>

@interface UIFontDescriptor (MADAdditions)

+ (instancetype)newFontDescriptorForFontName:(NSString *)fontname
									fontSize:(double)fontSize
										bold:(BOOL)bold
									  italic:(BOOL)italic;

@end

#endif
