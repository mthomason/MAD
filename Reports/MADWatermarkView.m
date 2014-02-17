//
//  MADWatermarkView.m
//  MAD
//
//  Created by Michael Thomason on 10/22/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MADWatermarkView.h"
#import "AppDelegate.h"

@interface MADWatermarkView ()

@property (nonatomic, retain) NSAttributedString *displayString;
@property (nonatomic, retain) NSAttributedString *displayString2;

@end

@implementation MADWatermarkView

- (void)dealloc {
    [_displayString release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    UIColor *bgColor = [UIColor groupTableViewBackgroundColor];
    [self setBackgroundColor: bgColor];
    
    NSMutableParagraphStyle *paragraphStart = [[NSMutableParagraphStyle alloc] init];
    [paragraphStart setLineBreakMode:NSLineBreakByWordWrapping];
    [paragraphStart setBaseWritingDirection:NSWritingDirectionLeftToRight];
    [paragraphStart setAlignment:NSTextAlignmentCenter];
    
    NSMutableParagraphStyle *paragraphEnd = [[NSMutableParagraphStyle alloc] init];
    [paragraphEnd setLineBreakMode:NSLineBreakByWordWrapping];
    [paragraphEnd setBaseWritingDirection:NSWritingDirectionLeftToRight];
    [paragraphEnd setAlignment:NSTextAlignmentCenter];
    
    CGFloat fontSize = 100.0000f;
    UIFont *customFont = [UIFont fontWithName:@"HelveticaNeue-CondensedBlack" size:fontSize];
    CGFloat fontSize2 = 44.5000f;
    UIFont *customFont2 = [UIFont fontWithName:@"HelveticaNeue-CondensedBlack" size:fontSize2];
    UIColor *foregroundColor = [UIColor lightTextColor];
    
    NSDictionary *attributes = @{
                                 //NSTextEffectAttributeName : NSTextEffectLetterpressStyle,
                                 NSForegroundColorAttributeName : foregroundColor,
                                 NSFontAttributeName : customFont
                                 };
    NSDictionary *attributes2 = @{
                                  //NSTextEffectAttributeName : NSTextEffectLetterpressStyle,
                                  NSForegroundColorAttributeName : foregroundColor,
                                  NSFontAttributeName : customFont2
                                  };
    
    NSString *getMadS = @"MAD";
    NSString *getMadD = [MTApplicationInstance isMadDesigner] ? @"DESIGNER" : @"";
    
    NSAttributedString *getMad = [[NSAttributedString alloc] initWithString: getMadS attributes:attributes];
    NSAttributedString *getDesigner = [[NSAttributedString alloc] initWithString: getMadD attributes:attributes2];
    
    
    [self setDisplayString:getMad];
    [self setDisplayString2:getDesigner];
    
    [getMad release];
    [getDesigner release];
    [paragraphStart release];
    [paragraphEnd release];
    
}

- (void)drawRect:(CGRect)rect {

    CGContextRef ctx = UIGraphicsGetCurrentContext();
    NSStringDrawingContext *sctx = [[NSStringDrawingContext alloc] init];

    NSInteger rowCounter = 0, columnCounter = 0;
    CGSize logoSize = [[self displayString] size];
    CGSize logoSize2 = [[self displayString2] size];
    CGSize logoMargin = CGSizeMake(45.0000f, 66.0000f);
    CGRect logoRect, logoRect2;
    
    CGFloat xHalfSize = logoMargin.width / 2.0000f - logoSize.width / 2.0000f;
    CGFloat xOffset = xHalfSize - 66.0000f;
    CGFloat yOffset = logoMargin.height / 2.0000f - logoSize.height / 2.0000f - 150.0000f;

    do {
        columnCounter = 0;
        
        do {
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
                CGRect rect2 = CGRectMake(0.0000f, 0.0000f, logoRect2.size.width, logoRect2.size.height);
                [[self displayString2] drawInRect:rect2];
                CGContextTranslateCTM(ctx, -2.0000f, -yt);
                CGRect rect1 = CGRectMake(0.0000f, 0.0000f, logoRect.size.width, logoRect.size.height);
                [[self displayString] drawInRect:rect1];
            }
            CGContextRestoreGState(ctx);
            columnCounter++;
        } while (logoRect.origin.x + logoRect.size.width < rect.size.width);
        rowCounter++;
    } while (logoRect.origin.y + logoRect.size.height < rect.size.height);
    [sctx release];

}


@end
