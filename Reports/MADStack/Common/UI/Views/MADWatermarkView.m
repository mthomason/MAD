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
#import <MAD/MADConstants.h>

NSString * const MADFontNameHelveticaNeueCondensedBlack = @"HelveticaNeue-CondensedBlack";

@implementation MADWatermarkView

+ (NSAttributedString *)waterMarkStringMad {
    UIColor *foregroundColor = [UIColor lightTextColor];
    UIFont *customFont = [UIFont fontWithName:MADFontNameHelveticaNeueCondensedBlack size:[UIApplication isMADDesigner] ? 100.0000f : 78.0000f];
    NSDictionary *attributes = @{
                                 NSForegroundColorAttributeName : foregroundColor,
                                 NSFontAttributeName : customFont
                                 };
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString: MADTrademark
                                                                           attributes: attributes];
    return attributedString;
}

+ (NSAttributedString *)waterMarkStringDesigner {
    NSString *displayStringText = [[[UIApplication AppDelegate] applicationNameSufixPart] uppercaseString];
    UIColor *foregroundColor = [UIColor lightTextColor];
    CGFloat fontSize =  [UIApplication isMADDesigner] ? 44.5000f : 46.0000f;
    UIFont *customFont = [UIFont fontWithName:MADFontNameHelveticaNeueCondensedBlack size:fontSize];
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [paragraphStyle setAlignment:NSTextAlignmentCenter];
    NSDictionary *attributes = @{
                                 NSForegroundColorAttributeName : foregroundColor,
                                 NSFontAttributeName : customFont,
                                 NSParagraphStyleAttributeName : paragraphStyle
                                 };
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString: displayStringText attributes:attributes];
    return attributedString;
}

+ (void)drawMadWatermarkInRect:(CGRect)rect {
    
    NSAttributedString *displayString = [self waterMarkStringMad];
    NSAttributedString *displayString2 = [self waterMarkStringDesigner];
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    NSInteger rowCounter = 0, columnCounter = 0;
    CGSize logoSize = [displayString size];
    CGSize logoSize2 = [displayString2 size];
    CGSize logoMargin = CGSizeMake(45.0000f, 66.0000f);
    CGRect logoRect, logoRect2;
    
    CGFloat xHalfSize = logoMargin.width / 2.0000f - logoSize.width / 2.0000f;
    CGFloat xOffset = xHalfSize - 66.0000f;
    CGFloat yOffset = logoMargin.height / 2.0000f - logoSize.height / 2.0000f - 150.0000f;
    
    do {
        columnCounter = 0;
        
        do {
            @autoreleasepool {
                
                BOOL moveLeft = rowCounter % 2 == 0;
                CGFloat x = ((columnCounter * 2) + 1) * logoMargin.width + columnCounter * logoSize.width + xOffset;
                CGFloat xQuarterSize = xOffset / 2;
                if (moveLeft) {
                    x -= xQuarterSize;
                } else {
                    x += xQuarterSize;
                }
                CGFloat y = ((rowCounter * 2) + 1) * logoMargin.height + rowCounter * logoSize.height + logoSize2.height + yOffset;
                logoRect = CGRectMake(x, y, logoSize.width, logoSize.height);
                CGFloat y2 = y + logoSize.height;
                logoRect2 = CGRectMake(x, y2, logoSize2.width, logoSize2.height);
                
                CGContextSaveGState(ctx);
                
                {
                    CGFloat yResolved = columnCounter % 2 == 0 ? y : y + ((logoRect.size.height + (logoMargin.height * 2)) / 2.0000f);
                    CGFloat yt = logoRect.size.height - 24.0000f;
                    CGFloat firstT = yResolved + yt;
                    x += 2.000f;
                    CGContextTranslateCTM(ctx, x, firstT);
                    
                    CGFloat rect2Offset = 0.0000f;
                    
                    CGRect rect2 = CGRectMake(rect2Offset, 0.0000f, logoRect2.size.width, logoRect2.size.height);
                    [displayString2 drawInRect:rect2];
                    CGContextTranslateCTM(ctx, -2.0000f, -yt);
                    CGRect rect1 = CGRectMake(0.0000f, 0.0000f, logoRect.size.width, logoRect.size.height);
                    [displayString drawInRect:rect1];
                }
                CGContextRestoreGState(ctx);
                
            }
            columnCounter++;
        } while (logoRect.origin.x + logoRect.size.width < rect.size.width);
        rowCounter++;
    } while (logoRect.origin.y + logoRect.size.height < rect.size.height);
    
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    UIColor *bgColor = [UIColor groupTableViewBackgroundColor];
    self.backgroundColor =  bgColor;
}

- (void)drawRect:(CGRect)rect {
    [MADWatermarkView drawMadWatermarkInRect:rect];
}

@end

@implementation MADWatermarkScrollView

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    UIColor *bgColor = [UIColor groupTableViewBackgroundColor];
    self.backgroundColor =  bgColor;
    self.showsHorizontalScrollIndicator = YES;
    self.showsVerticalScrollIndicator = YES;
    self.contentOffset = CGPointZero;
    self.maximumZoomScale = 1.0000f;
    self.minimumZoomScale = 1.0000f;
    self.zoomScale = 1.0000f;
    self.scrollEnabled = YES;
    self.bounces = YES;
    self.alwaysBounceHorizontal = YES;
    self.alwaysBounceVertical = YES;
    self.bouncesZoom = NO;
    self.delaysContentTouches = YES;
    self.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.translatesAutoresizingMaskIntoConstraints = NO;
}

- (void)drawRect:(CGRect)rect {
    [MADWatermarkView drawMadWatermarkInRect:rect];
}

@end
