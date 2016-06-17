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

@class RptqDocumentObject;

@interface UIFontDescriptor (DocumentObject)

    + (instancetype)newFontDescriptorForDocumentObject:(RptqDocumentObject *)documentObject;

@end

#endif
