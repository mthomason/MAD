//
//  MADFontDescriptor
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
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
