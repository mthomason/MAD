//
//  UIFontDescriptor+DocumentObject.m
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "UIFontDescriptor+DocumentObject.h"
#import "RptqDocumentElement+CoreDataClass.h"

@implementation MADFontDescriptor

+ (instancetype)newFontDescriptorForFontName:(NSString *) fontname
                                    fontSize:(NSNumber *) fontSize
                                        bold:(BOOL)bold
                                      italic:(BOOL)italic {

    NSString *name;
    NSNumber *size;;
    
    name = fontname.copy;
    size = fontSize.copy;

    UIFontDescriptorSymbolicTraits traits = 0;
    if (italic) traits     |= UIFontDescriptorTraitItalic;
    if (bold)   traits     |= UIFontDescriptorTraitBold;
    
    NSValue *traitsWrapper = @(traits);
    NSDictionary *symbolicTraits = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    traitsWrapper, UIFontSymbolicTrait, nil];
    
    NSDictionary *fontAttributes;
    fontAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    name,       UIFontDescriptorFamilyAttribute,
                                    size,       UIFontDescriptorSizeAttribute,
                                    symbolicTraits, UIFontDescriptorTraitsAttribute, nil];
    
    id fontDescriptor;
    fontDescriptor = [[UIFontDescriptor alloc] initWithFontAttributes:fontAttributes];
    return fontDescriptor;
}

@end
