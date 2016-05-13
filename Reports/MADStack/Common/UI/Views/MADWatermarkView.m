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
#import <UIKit/UILabel.h>
#import <UIKit/NSAttributedString.h>
#import <UIKit/NSStringDrawing.h>
#import <MADFoundation/MADAppDelegate.h>
#import <MADFoundation/UIApplication+MADAppDelegate.h>

typedef void (^MADWatermarkAddLabel)(CGRect, NSAttributedString *, UIView * __autoreleasing *);

static NSString * const MADFontNameHelveticaNeueCondensedBlack = @"HelveticaNeue-CondensedBlack";

static const CGFloat offset = 2.0;

static inline CGRect LogoRect1(CGPoint origin, CGSize size);
static inline CGRect LogoRect1(CGPoint origin, CGSize size) {
    return CGRectMake(origin.x, origin.y, size.width, size.height);
}

static inline CGRect LogoRect2(CGPoint origin, const CGSize size[2]);
static inline CGRect LogoRect2(CGPoint origin, const CGSize size[2]) {
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

static inline CGFloat LogoPointOriginY(NSUInteger rowCounter, CGFloat marginHeight, const CGSize strings[2]);
static inline CGFloat LogoPointOriginY(NSUInteger rowCounter, CGFloat marginHeight, const CGSize strings[2]) {
    return ((rowCounter * 2) + 1) * marginHeight +
            rowCounter * strings[0].height +
            strings[1].height +
            (marginHeight / 2.0000f - strings[0].height / 2.0000f - 150.0000f);
}

static inline CGRect BoundsForRect(CGRect rect);
static inline CGRect BoundsForRect(CGRect rect) {
    return CGRectMake(CGPointZero.x, CGPointZero.y, rect.size.width, rect.size.height);
}

static inline CGFloat LogoPointOriginYResolved(NSUInteger columnCounter, CGFloat originY, CGRect rect, CGFloat marginHeight);
static inline CGFloat LogoPointOriginYResolved(NSUInteger columnCounter, CGFloat originY, CGRect rect, CGFloat marginHeight) {
    return columnCounter % 2 == 0 ? originY : originY + ((rect.size.height + (marginHeight * 2)) / 2.0000f);
}

static inline CGFloat LogoPointOriginYt(CGFloat height);
static inline CGFloat LogoPointOriginYt(CGFloat height) {
    return height - 24.0000f;
}

static CGFloat FirstT(NSUInteger counter, CGFloat originY, CGRect logoRect, CGFloat marginHeight);
static CGFloat FirstT(NSUInteger counter, CGFloat originY, CGRect logoRect, CGFloat marginHeight) {
    return LogoPointOriginYResolved(counter, originY, logoRect, marginHeight) + LogoPointOriginYt(logoRect.size.height);
}

static CGRect LRect1(CGPoint origin, CGRect *logoRect, NSUInteger counter, CGFloat marginHeight);
static CGRect LRect1(CGPoint origin, CGRect *logoRect, NSUInteger counter, CGFloat marginHeight) {
    return CGRectMake(origin.x,
                      FirstT(counter, origin.y, *logoRect, marginHeight) -
                      LogoPointOriginYt((*logoRect).size.height),
                      (*logoRect).size.width,
                      (*logoRect).size.height);
}

static CGRect LRect2(CGPoint origin, CGRect (*logoRect)[2], NSUInteger counter, CGFloat marginHeight);
static CGRect LRect2(CGPoint origin, CGRect (*logoRect)[2], NSUInteger counter, CGFloat marginHeight) {
    return CGRectMake(origin.x,
                      FirstT(counter, origin.y, (*logoRect)[0], marginHeight),
                      (*logoRect)[1].size.width,
                      (*logoRect)[1].size.height);
}


static bool ShiftDisplay(NSUInteger counter);
static bool ShiftDisplay(NSUInteger counter) {
    return counter % 2 == 0;
}

static CGPoint LogoOrigin(NSUInteger counter[2], const CGSize strings[2], CGSize logoMargin);
static CGPoint LogoOrigin(NSUInteger counter[2], const CGSize strings[2], CGSize logoMargin) {
    return CGPointMake(LogoPointOriginX(counter[0], logoMargin.width, strings[0], ShiftDisplay(counter[1])),
                       LogoPointOriginY(counter[1], logoMargin.height, strings));
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
        [MADWatermarkView drawBackground:frame onView:&self];
    }
    return self;
}

+ (void)drawBackground:(CGRect)rect onView:(UIView * __autoreleasing *)view {
    const CGSize logoMargin = CGSizeMake(45.0000f, 66.0000f);
    
    NSAttributedString *displayString = [MADWatermarkView newWaterMarkStringMad];
    NSAttributedString *displayString2 = [MADWatermarkView newWaterMarkStringDesigner];
    const CGSize strings[2] = {displayString.size, displayString2.size};
    NSUInteger counter[2] = {0, 0};
    CGRect logoRect[2];

    MADWatermarkAddLabel addLabel = ^(CGRect labelFrame, NSAttributedString *string, UIView *__autoreleasing *backgroundView) {
        UILabel *l2 = [[UILabel alloc] initWithFrame:labelFrame];
        l2.attributedText = string;
        l2.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        [*backgroundView addSubview:l2];
    };
    
    do {
        counter[0] = 0;
        do {

            logoRect[0] = LogoRect1(LogoOrigin(counter, strings, logoMargin), strings[0]);
            logoRect[1] = LogoRect2(LogoOrigin(counter, strings, logoMargin), strings);
            
            addLabel(LRect1(
                            LogoOrigin(counter, strings, logoMargin), &logoRect[0], counter[0], logoMargin.height),
                     displayString,
                     view);
            
            
            addLabel(LRect2(
                            LogoOrigin(counter, strings, logoMargin), &logoRect, counter[0], logoMargin.height),
                     displayString2,
                     view);


            counter[0]++;
            
        } while (logoRect[0].origin.x + logoRect[0].size.width < rect.size.width);
        
        counter[1]++;
        
    } while (logoRect[0].origin.y + logoRect[0].size.height < rect.size.height);
}

@end
