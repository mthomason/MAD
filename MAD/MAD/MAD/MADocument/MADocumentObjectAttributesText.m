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
#import "RptqDocumentElement+CoreDataClass.h"
#import "MTAlignment.h"

@interface MADocumentObjectAttributesText ()

    - (instancetype)init NS_DESIGNATED_INITIALIZER;
    @property (nonatomic, strong, readwrite) NSDictionary *fontAttributes;

@end

@implementation MADocumentObjectAttributesText

- (instancetype)init {
    return (self = [super init]);
}

- (nullable instancetype)initWithFontName:(NSString * _Nullable) fontname
                                 fontSize:(NSNumber * _Nullable) fontsize
                                     bold:(BOOL)bold
                                   italic:(BOOL)italic
                                underline:(BOOL)underline
                                   strike:(BOOL)strike
                      horizontalAlignment:(NSTextAlignment)horizontalAlignment {
    
    if (self = [super init]) {
    
        UIFontDescriptor *fontDescriptor;
        fontDescriptor = [MADFontDescriptor newFontDescriptorForFontName: fontname
                                                                fontSize: fontsize
                                                                    bold: bold
                                                                  italic: italic];
    
        
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
        NSNumber *underlineStyle = [[NSNumber alloc] initWithInteger: underline ?
                                              NSUnderlineStyleSingle: NSUnderlineStyleNone];
        
        NSNumber *strikethroughStyle = [[NSNumber alloc] initWithInteger: strike ?
                                                  NSUnderlineStyleSingle: NSUnderlineStyleNone];
        
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

@end
