//
//  UIFontDescriptor+DocumentObject.h
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MAD_UIFontDescriptor__DocumentObject_h
#define Reports_MAD_UIFontDescriptor__DocumentObject_h

#import <UIKit/UIFontDescriptor.h>

@class RptqDocumentElement;

@interface MADFontDescriptor : UIFontDescriptor

    + (instancetype)newFontDescriptorForFontName:(NSString *) fontname
                                        fontSize:(float) fontSize
                                            bold:(BOOL)bold
                                          italic:(BOOL)italic;

@end

#endif
