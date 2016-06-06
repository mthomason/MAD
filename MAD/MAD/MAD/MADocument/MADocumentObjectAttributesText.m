//
//  MADocumentObjectTextAttributes.m
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADocumentObjectAttributesText.h"
#import "UIFontDescriptor+DocumentObject.h"
#import <UIKit/UIFontDescriptor.h>
#import <UIKit/UIFont.h>
#import <UIKit/NSParagraphStyle.h>
#import <UIKit/NSAttributedString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>
#import "RptqDocumentObject.h"
#import "MTAlignment.h"

@interface MADocumentObjectAttributesText ()

    @property (nonatomic, strong, readwrite) UIFontDescriptor *fontDescriptor;
    @property (nonatomic, strong, readwrite) NSDictionary *fontAttributes;

@end

@implementation MADocumentObjectAttributesText

- (nullable instancetype)initWithObject:(RptqDocumentObject * _Nonnull)object
                      andFontDescriptor:(UIFontDescriptor * _Nullable)fontDescriptor {
    
    if (self = [super initWithObject:object]) {
    
        if (fontDescriptor == nil)
            fontDescriptor = [UIFontDescriptor newFontDescriptorForDocumentObject:object];
    
        _fontDescriptor = fontDescriptor.copy;
        
        UIFont *customFont = [UIFont fontWithDescriptor: _fontDescriptor
                                                   size: 0.0];
        
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        // ???: Where is NSLineBreakByClipping in iOS7... There attributed string is buggy as fuck.
        paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
        paragraphStyle.baseWritingDirection = NSWritingDirectionLeftToRight;
        
        switch (object.horizontalAlignment.integerValue) {
            case MTHorizontalAlignmentLeft:
                paragraphStyle.alignment = NSTextAlignmentLeft;
                break;
            case MTHorizontalAlignmentRight:
                paragraphStyle.alignment = NSTextAlignmentRight;
                break;
            case MTHorizontalAlignmentCenter:
                paragraphStyle.alignment = NSTextAlignmentCenter;
                break;
            case MTHorizontalAlignmentJustified:
                paragraphStyle.alignment = NSTextAlignmentJustified;
                break;
            case MTHorizontalAlignmentNatrual:
                paragraphStyle.alignment = NSTextAlignmentNatural;
                break;
            default:
                paragraphStyle.alignment = NSTextAlignmentLeft;
                break;
        }
        
        NSNumber *baselineOffset = @0.00000000f;
        NSNumber *underlineStyle = [[NSNumber alloc] initWithInteger: object.underline.boolValue ?
                                             NSUnderlineStyleSingle : NSUnderlineStyleNone];
        NSNumber *strikethroughStyle = [[NSNumber alloc] initWithInteger:object.strike.boolValue ?
                                                 NSUnderlineStyleSingle : NSUnderlineStyleNone];
        
        NSDictionary *fontAttributes;
        fontAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    customFont,         NSFontAttributeName,
                                    baselineOffset,     NSBaselineOffsetAttributeName,
                                    underlineStyle,     NSUnderlineStyleAttributeName,
                                    strikethroughStyle, NSStrikethroughStyleAttributeName,
                                    paragraphStyle,     NSParagraphStyleAttributeName, nil];
        
        self.fontAttributes = fontAttributes;
        
    }
    return self;
    
}

- (nullable instancetype)initWithObject:(RptqDocumentObject * _Nonnull)object {
    return [self initWithObject:object andFontDescriptor:nil];
}

@end
