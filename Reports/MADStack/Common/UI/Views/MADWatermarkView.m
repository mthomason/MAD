//
//  MADWatermarkView.m
//  MAD
//
//  Created by Michael Thomason on 10/22/13.
//  Copyright © 2020 Michael Thomason. All rights reserved.
//

#import "MADWatermarkView.h"
#import <Foundation/NSAttributedString.h>
#import <UIKit/UIGraphics.h>
#import <UIKit/UILabel.h>
#import <UIKit/NSAttributedString.h>
#import <UIKit/NSStringDrawing.h>
#import <MADFoundation/MADAppDelegate.h>
#import <MADFoundation/MADApplication.h>
#import <MADFoundation/MADApplicationProtocol.h>

typedef void (^MADWatermarkAddLabel)(CGRect, NSAttributedString *, UIView *);

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
    return (marginWidth / 2.0 - string.width / 2.0) - 66.0;
}

static inline CGFloat LogoPointOriginX(NSUInteger columnCounter, CGFloat marginWidth, CGSize string, BOOL moveLeft);
static inline CGFloat LogoPointOriginX(NSUInteger columnCounter, CGFloat marginWidth, CGSize string, BOOL moveLeft) {
    return ((columnCounter * 2) + 1) * marginWidth + columnCounter * string.width +
    (LogoPointOriginXOffset(marginWidth, string) * (moveLeft ? -1 : 2));
}

static inline CGFloat LogoPointOriginY(NSUInteger rowCounter, CGFloat marginHeight, const CGSize strings[2]);
static inline CGFloat LogoPointOriginY(NSUInteger rowCounter, CGFloat marginHeight, const CGSize strings[2]) {
    return ((rowCounter * 2) + 1) * marginHeight +
            rowCounter * strings[0].height +
            strings[1].height +
            (marginHeight / 2.0 - strings[0].height / 2.0 - 150.0);
}

static inline CGFloat LogoPointOriginYResolved(NSUInteger columnCounter, CGFloat originY, CGRect rect, CGFloat marginHeight);
static inline CGFloat LogoPointOriginYResolved(NSUInteger columnCounter, CGFloat originY, CGRect rect, CGFloat marginHeight) {
    return columnCounter % 2 == 0 ? originY : originY + ((rect.size.height + (marginHeight * 2)) / 2.0);
}

static inline CGFloat LogoPointOriginYt(CGFloat height);
static inline CGFloat LogoPointOriginYt(CGFloat height) {
    return height - 24.0;
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


static BOOL ShiftDisplay(NSUInteger counter);
static BOOL ShiftDisplay(NSUInteger counter) {
    return counter % 2 == 0;
}

static CGPoint LogoOrigin(NSUInteger counter[2], const CGSize strings[2], CGSize logoMargin);
static CGPoint LogoOrigin(NSUInteger counter[2], const CGSize strings[2], CGSize logoMargin) {
    return CGPointMake(LogoPointOriginX(counter[0], logoMargin.width, strings[0], ShiftDisplay(counter[1])),
                       LogoPointOriginY(counter[1], logoMargin.height, strings));
}

@interface MADWatermarkView()

@end

@interface MADWatermarkString : NSAttributedString

    + (instancetype)newWaterMarkStringMad;
    + (instancetype)newWaterMarkStringDesigner;

@end

@implementation MADWatermarkView {
    BOOL _drawn;
}

- (void)dealloc { }

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
		UIColor *bgColor = [UIColor systemGroupedBackgroundColor];
        self.backgroundColor =  bgColor;
        _drawn = NO;
    }
    return self;
}

/*- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    //if (!newSuperview) {
    //    for (UIView *subview in self.subviews) {
    //        [subview removeFromSuperview];
    //    }
    //}
}*/

/*- (void)layoutSubviews {
    [super layoutSubviews];
    if (!_drawn) {
        _drawn = YES;
        [self drawBackground];
    }
}*/

// Uses about 10 MB of VM
- (void)drawBackground {

    CGRect rect = self.frame;
    const CGSize logoMargin = CGSizeMake(45.0, 66.0);

    NSAttributedString *displayString = [MADWatermarkString newWaterMarkStringMad];
    NSAttributedString *displayString2 = [MADWatermarkString newWaterMarkStringDesigner];
    const CGSize strings[2] = {displayString.size, displayString2.size};
    NSUInteger counter[2] = {0, 0};
    CGRect logoRect[2];
    
    do {
        counter[0] = 0;
        do {
            logoRect[0] = LogoRect1(LogoOrigin(counter, strings, logoMargin), strings[0]);
            logoRect[1] = LogoRect2(LogoOrigin(counter, strings, logoMargin), strings);

            @autoreleasepool {
                
                UILabel *l2 = [[UILabel alloc] initWithFrame:LRect1(LogoOrigin(counter, strings, logoMargin), &logoRect[0], counter[0], logoMargin.height)];
                l2.attributedText = displayString.copy;;
                l2.autoresizingMask = UIViewAutoresizingFlexibleRightMargin |
                UIViewAutoresizingFlexibleBottomMargin;
                [self addSubview:l2];
                
                l2 = [[UILabel alloc] initWithFrame:LRect2(LogoOrigin(counter, strings, logoMargin), &logoRect, counter[0], logoMargin.height)];
                l2.attributedText = displayString2.copy;;
                l2.autoresizingMask = UIViewAutoresizingFlexibleRightMargin |
                UIViewAutoresizingFlexibleBottomMargin;
                [self addSubview:l2];
                l2 = nil;
                
            }
            counter[0]++;
            
        } while (logoRect[0].origin.x + logoRect[0].size.width < rect.size.width);
        
        counter[1]++;
        
    } while (logoRect[0].origin.y + logoRect[0].size.height < rect.size.height);
 
}

@end

@implementation MADWatermarkString

static NSString * const MADFontNameHelveticaNeueCondensedBlack = @"HelveticaNeue-CondensedBlack";

+ (instancetype)newWaterMarkStringMad {
    
    UIColor *foregroundColor = [UIColor lightTextColor];

    UIFont *customFont = [UIFont fontWithName:MADFontNameHelveticaNeueCondensedBlack
                                         size:[MADApplication isMADDesigner] ? 100.0 : 78.0];

    NSDictionary *attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                                            foregroundColor, NSForegroundColorAttributeName,
                                            customFont, NSFontAttributeName, nil];
    
    NSString *trademark = [[MADApplication AppDelegate] trademark];
    
    id attributedString = [[NSAttributedString alloc] initWithString: trademark
                                                          attributes: attributes];
    return attributedString;
}

+ (instancetype)newWaterMarkStringDesigner {

    UIColor *foregroundColor = [UIColor lightTextColor];

    UIFont *customFont = [UIFont fontWithName: MADFontNameHelveticaNeueCondensedBlack
                                         size: [MADApplication isMADDesigner] ? 44.5 : 46.0];

    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.alignment = NSTextAlignmentCenter;

    id attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                                foregroundColor, NSForegroundColorAttributeName,
                                customFont, NSFontAttributeName,
                                paragraphStyle, NSParagraphStyleAttributeName, nil];

    NSString *suffix = [[MADApplication AppDelegate] applicationNameSufixPart].uppercaseString;
    id attributedString = [[NSAttributedString alloc] initWithString: suffix
                                                          attributes: attributes];
    return attributedString;
}

@end
