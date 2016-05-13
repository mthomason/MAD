//
//  MADWatermarkView.m
//  MAD
//
//  Created by Michael Thomason on 10/22/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADWatermarkView.h"
#import <Foundation/NSAttributedString.h>
#import <UIKit/UIGraphics.h>
#import <UIKit/NSAttributedString.h>
#import <UIKit/NSStringDrawing.h>
#import <MADFoundation/MADAppDelegate.h>
#import <MADFoundation/UIApplication+MADAppDelegate.h>

static NSString * const MADFontNameHelveticaNeueCondensedBlack = @"HelveticaNeue-CondensedBlack";

static const CGFloat offset = 2.0;

static inline CGRect LogoRect1(CGPoint origin, CGSize size);
static inline CGRect LogoRect1(CGPoint origin, CGSize size) {
    return CGRectMake(origin.x, origin.y, size.width, size.height);
}

static inline CGRect LogoRect2(CGPoint origin, CGSize size[2]);
static inline CGRect LogoRect2(CGPoint origin, CGSize size[2]) {
    return CGRectMake(origin.x, origin.y + size[0].height, size[1].width, size[1].height);
}

static inline CGFloat LogoPointOriginXOffset(CGFloat marginWidth, CGSize string);
static inline CGFloat LogoPointOriginXOffset(CGFloat marginWidth, CGSize string) {
    return (marginWidth / 2.0000f - string.width / 2.0000f) - 66.0000f;
}

static inline CGFloat LogoPointOriginX(NSUInteger columnCounter, CGFloat marginWidth, CGSize string, bool moveLeft);
static inline CGFloat LogoPointOriginX(NSUInteger columnCounter, CGFloat marginWidth, CGSize string, bool moveLeft) {
    return ((columnCounter * 2) + 1) * marginWidth + columnCounter * string.width +
    (LogoPointOriginXOffset(marginWidth, string) * (moveLeft ? -1 : 2));
}

static inline CGFloat LogoPointOriginY(NSUInteger rowCounter, CGFloat marginHeight, CGSize strings[2]);
static inline CGFloat LogoPointOriginY(NSUInteger rowCounter, CGFloat marginHeight, CGSize strings[2]) {
    return ((rowCounter * 2) + 1) * marginHeight +
            rowCounter * strings[0].height +
            strings[1].height +
            (marginHeight / 2.0000f - strings[0].height / 2.0000f - 150.0000f);
}

static inline CGRect BoundsForRect(CGRect rect);
static inline CGRect BoundsForRect(CGRect rect) {
    return CGRectMake(CGPointZero.x, CGPointZero.y, rect.size.width, rect.size.height);
}

static inline CGFloat LogoPointOriginYResolved(NSUInteger columnCounter, CGPoint origin, CGRect rect, CGFloat marginHeight);
static inline CGFloat LogoPointOriginYResolved(NSUInteger columnCounter, CGPoint origin, CGRect rect, CGFloat marginHeight) {
    return columnCounter % 2 == 0 ? origin.y : origin.y + ((rect.size.height + (marginHeight * 2)) / 2.0000f);
}

static inline CGFloat LogoPointOriginYt(CGFloat height);
static inline CGFloat LogoPointOriginYt(CGFloat height) {
    return height - 24.0000f;
}

@implementation MADWatermarkView

+ (NSAttributedString *)newWaterMarkStringMad {

    UIColor *foregroundColor = [UIColor lightTextColor];

    UIFont *customFont = [UIFont fontWithName:MADFontNameHelveticaNeueCondensedBlack
                                         size:[MADApplication isMADDesigner] ? 100.0000f : 78.0000f];

    NSDictionary *attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                                            foregroundColor, NSForegroundColorAttributeName,
                                            customFont, NSFontAttributeName, nil];
    
    NSString *trademark = [[MADApplication AppDelegate] trademark].copy;
    
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString: trademark
                                                                           attributes: attributes];
    return attributedString;
}

+ (NSAttributedString *)newWaterMarkStringDesigner {

    UIColor *foregroundColor = [UIColor lightTextColor];

    UIFont *customFont = [UIFont fontWithName: MADFontNameHelveticaNeueCondensedBlack
                                         size: [MADApplication isMADDesigner] ? 44.5000f : 46.0000f];

    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.alignment = NSTextAlignmentCenter;

    id attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                                foregroundColor, NSForegroundColorAttributeName,
                                customFont, NSFontAttributeName,
                                paragraphStyle, NSParagraphStyleAttributeName, nil];

    NSString *suffix = [[MADApplication AppDelegate] applicationNameSufixPart].uppercaseString;
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString: suffix
                                                                           attributes: attributes];
    return attributedString;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        UIColor *bgColor = [UIColor groupTableViewBackgroundColor];
        self.backgroundColor =  bgColor;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        UIColor *bgColor = [UIColor groupTableViewBackgroundColor];
        self.backgroundColor =  bgColor;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    const CGSize logoMargin = CGSizeMake(45.0000f, 66.0000f);
    
    NSAttributedString *displayString = [MADWatermarkView newWaterMarkStringMad];
    NSAttributedString *displayString2 = [MADWatermarkView newWaterMarkStringDesigner];
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    
    CGSize strings[2] = {displayString.size, displayString2.size};
    NSUInteger counter[2] = {0, 0};
    CGRect logoRect[2];
    CGPoint origin;
    
    do {
        counter[0] = 0;
        do {
            @autoreleasepool {
            bool moveLeft = counter[1] % 2 == 0;
            origin.x = LogoPointOriginX(counter[0], logoMargin.width, strings[0], moveLeft);
            origin.y = LogoPointOriginY(counter[1], logoMargin.height, strings);
            logoRect[0] = LogoRect1(origin, strings[0]);
            logoRect[1] = LogoRect2(origin, strings);
            
            CGContextSaveGState(ctx);
            {
            
            CGContextShowText(<#CGContextRef  _Nullable c#>, <#const char * _Nullable string#>, <#size_t length#>)
            
                CGFloat firstT = LogoPointOriginYResolved(counter[0], origin, logoRect[0], logoMargin.height) +
                                    LogoPointOriginYt(logoRect[0].size.height);
                origin.x += offset;
                CGContextTranslateCTM(ctx, origin.x, firstT);
                [displayString2 drawInRect:BoundsForRect(logoRect[1])];
                
                CGContextTranslateCTM(ctx, -offset, -LogoPointOriginYt(logoRect[0].size.height));
                [displayString drawInRect:BoundsForRect(logoRect[0])];
            }
            CGContextRestoreGState(ctx);
            
            }
            counter[0]++;
        } while (logoRect[0].origin.x + logoRect[0].size.width < rect.size.width);
        counter[1]++;
    } while (logoRect[0].origin.y + logoRect[0].size.height < rect.size.height);
}

@end
