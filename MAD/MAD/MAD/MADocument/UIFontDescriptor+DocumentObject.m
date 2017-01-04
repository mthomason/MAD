//
//  UIFontDescriptor+DocumentObject.m
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "UIFontDescriptor+DocumentObject.h"
#import "RptqDocumentObject.h"

@implementation MADFontDescriptor

+ (instancetype)newFontDescriptorForDocumentObject:(RptqDocumentObject *)object {

    UIFontDescriptorSymbolicTraits traits = 0;
    if (object.italic.boolValue) traits     |= UIFontDescriptorTraitItalic;
    if (object.bold.boolValue)   traits     |= UIFontDescriptorTraitBold;
    
    NSNumber *traitsWrapper = [[NSNumber alloc] initWithUnsignedInt: traits];
    
    NSDictionary *symbolicTraits = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    traitsWrapper, UIFontSymbolicTrait, nil];
    
    NSString *fontname = object.fontname.copy;
    NSNumber *fontsize = object.fontsize.copy;
    NSDictionary *fontAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    fontname,       UIFontDescriptorFamilyAttribute,
                                    fontsize,       UIFontDescriptorSizeAttribute,
                                    symbolicTraits, UIFontDescriptorTraitsAttribute, nil];
    
    UIFontDescriptor *fontDescriptor;
    fontDescriptor = [[UIFontDescriptor alloc] initWithFontAttributes:fontAttributes];
    return fontDescriptor;
}

@end
