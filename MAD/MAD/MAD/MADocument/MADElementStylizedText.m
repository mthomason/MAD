//
//  MADocumentObjectTextAttributes.m
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADElementStylizedText.h"
#import <UIKit/UIFontDescriptor.h>
#import <UIKit/UIFont.h>
#import <UIKit/NSParagraphStyle.h>
#import <UIKit/NSAttributedString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>
#import <MADCocoaExtensions/MADTextStyle.h>
#import "MADFontDescriptor.h"
#import "RptqDocumentElement.h"
#import "RptqTextStyle.h"
#import "MADAlignment.h"

@interface MADElementStylizedText ()

    - (instancetype)init NS_DESIGNATED_INITIALIZER;
    @property (nonatomic, strong, readwrite) NSMutableDictionary *fontAttributes;

@end

@implementation MADElementStylizedText

- (instancetype)init {
    return (self = [super init]);
}

- (nullable instancetype)initWithFontName:(NSString * _Nullable) fontname
                                 fontSize:(double) fontsize
                                textStyle:(RptqTextStyle *)textStyle
                      horizontalAlignment:(MADHorizontalAlignment)horizontalAlignment {
    
    if (self = [super init]) {
    
        UIFontDescriptor *fontDescriptor;
        fontDescriptor = [MADFontDescriptor newFontDescriptorForFontName: fontname
                                                                fontSize: fontsize
                                                                    bold: textStyle.bold
                                                                  italic: textStyle.italic];
    
        
        UIFont *customFont = [UIFont fontWithDescriptor: fontDescriptor
                                                   size: 0.0];


        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        // ???: Where is NSLineBreakByClipping in iOS7... There attributed string is buggy as fuck.
        paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
        paragraphStyle.baseWritingDirection = NSWritingDirectionLeftToRight;
        
        switch (horizontalAlignment) {
            case MADHorizontalAlignmentLeft:
                paragraphStyle.alignment = NSTextAlignmentLeft;
                break;
            case MADHorizontalAlignmentRight:
                paragraphStyle.alignment = NSTextAlignmentRight;
                break;
            case MADHorizontalAlignmentCenter:
                paragraphStyle.alignment = NSTextAlignmentCenter;
                break;
            case MADHorizontalAlignmentJustified:
                paragraphStyle.alignment = NSTextAlignmentJustified;
                break;
            case MADHorizontalAlignmentNatrual:
                paragraphStyle.alignment = NSTextAlignmentNatural;
                break;
            default:
                paragraphStyle.alignment = NSTextAlignmentLeft;
                break;
        }
        
        NSNumber *baselineOffset = @0.00000000f;
        NSNumber *underlineStyle;
        underlineStyle = [[NSNumber alloc] initWithInteger: textStyle.underline ?
                                              NSUnderlineStyleSingle :
                                              NSUnderlineStyleNone];
        
        NSNumber *strikethroughStyle;
        strikethroughStyle = [[NSNumber alloc] initWithInteger: textStyle.strikethrough ?
                                                                        NSUnderlineStyleSingle :
                                                                        NSUnderlineStyleNone];
        
        NSMutableDictionary *fontAttributes;
        fontAttributes = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                    customFont,         NSFontAttributeName,
                                    baselineOffset,     NSBaselineOffsetAttributeName,
                                    underlineStyle,     NSUnderlineStyleAttributeName,
                                    strikethroughStyle, NSStrikethroughStyleAttributeName,
                                    paragraphStyle,     NSParagraphStyleAttributeName, nil];
        
        self.fontAttributes = fontAttributes;
        
    }
    return self;
    
}

@end
