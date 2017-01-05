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

    NSString *fontname;
    NSNumber *fontsize, *italic, *bold;
    italic = object.italic;
    bold = object.bold;
    
    UIFontDescriptorSymbolicTraits traits = 0;
    if (italic.boolValue) traits     |= UIFontDescriptorTraitItalic;
    if (bold.boolValue)   traits     |= UIFontDescriptorTraitBold;
    
    NSNumber *traitsWrapper = [[NSNumber alloc] initWithUnsignedInt: traits];
    
    NSDictionary *symbolicTraits = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    traitsWrapper, UIFontSymbolicTrait, nil];
    
    fontname = object.fontname.copy;
    fontsize = object.fontsize.copy;
    
    NSDictionary *fontAttributes;
    fontAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    fontname,       UIFontDescriptorFamilyAttribute,
                                    fontsize,       UIFontDescriptorSizeAttribute,
                                    symbolicTraits, UIFontDescriptorTraitsAttribute, nil];
    
    UIFontDescriptor *fontDescriptor;
    fontDescriptor = [[UIFontDescriptor alloc] initWithFontAttributes:fontAttributes];
    return fontDescriptor;
}

@end
