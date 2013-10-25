//
//  MTCollectionViewCellDocument.m
//  Reports
//
//  Created by Michael Thomason on 2/19/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTCollectionViewCellDocument.h"
#import "UIDevice+Hack.h"

@implementation MTCollectionViewCellDocument

- (void)dealloc {
    //[_labelTitle release];
    //[_imagePreview release];
    [super dealloc];
}

- (void)awakeFromNib {
    CGFloat offset = 2.0000f * [[UIScreen mainScreen] scale];
    
    [[[self imagePreview] layer] setShadowColor:[[UIColor darkGrayColor] CGColor]];
    [[[self imagePreview] layer] setShadowRadius:2.0000f];
    [[[self imagePreview] layer] setShadowOpacity:1.0000f];
    CGSize offsetSize = CGSizeMake(offset, offset);
    [[[self imagePreview] layer] setShadowOffset:offsetSize];

    [[self labelTitle] setTextColor:[UIColor tintColor]];
    [[self labelTitle] setClipsToBounds:NO];
    
    [[[self selectedBackgroundView] layer] setCornerRadius:5.0000f];
    
    [[self imagePreview] setContentMode:UIViewContentModeScaleAspectFit];
    
    [super awakeFromNib];
}

- (void)performSelectionAnimations {
    [[self labelTitle] setTextColor:[UIColor whiteColor]];
}

- (void)performDeselectionAnimations {
    [[self labelTitle] setTextColor:[UIColor tintColor]];
}

- (void)setText:(NSString *)text {
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
    [paragraphStyle setBaseWritingDirection:NSWritingDirectionLeftToRight];
    [paragraphStyle setAlignment:NSTextAlignmentCenter];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text];
    NSInteger length = [[attributedString string] length];
    CGFloat size = [UIDevice isPad] ? 22.0000f : 12.0000f;
    UIFont *fonta = [UIFont systemFontOfSize:size];
    NSRange range = NSMakeRange(0, length);
    [attributedString addAttribute:NSKernAttributeName value:[NSNull null] range:range];
    [attributedString addAttribute:NSFontAttributeName value:fonta range:range];
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:range];
    //[attributedString addAttribute:NSStrokeWidthAttributeName value:@(1.0) range:range];
    //[attributedString addAttribute:NSStrokeColorAttributeName value:[UIColor whiteColor] range:range];
    //[attributedString addAttribute:NSTextEffectAttributeName value:NSTextEffectLetterpressStyle range:range];
    [[self labelTitle] setAttributedText:attributedString];
    [paragraphStyle release];

}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        UIView *selectedBackground = [[UIView alloc] initWithFrame:[self frame]];
        if ([UIDevice isLagacyOS]) {
            [[selectedBackground layer] setCornerRadius: 1.0000f];
        }
        [selectedBackground setClipsToBounds:YES];
        if ([UIDevice isModernOS]) {
            [selectedBackground setBackgroundColor:[UIColor edaBlackTwentyFivePercent]];
        }
        
        [self setSelectedBackgroundView:selectedBackground];
        [selectedBackground release];
        
        
    }
    return self;
}



- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    BOOL result = NO;
    if (action == @selector(email:) || action == @selector(delete:) || action == @selector(rename:)) {
        result = YES;
    }
    return result;
}

//- (void)setSelected:(BOOL)selected {
//}

- (BOOL)resignFirstResponder {
    [[self labelTitle] setTextColor:[UIColor tintColor]];
    return YES;
}

- (BOOL)becomeFirstResponder {
    [[self labelTitle] setTextColor:[UIColor whiteColor]];
    return YES;
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)delete:(id)sender {
    [[self delegate] deleteDocumentRepresentedByCell:self];
}

- (void)email:(id)sender {
    [[self delegate] email:self];
}

- (void)rename:(id)sender {
    [[self delegate] rename:self];
}

- (void)dimTint {
    [[self selectedBackgroundView] setBackgroundColor:[UIColor lightGrayColor]];
    [[self labelTitle] setTextColor:[UIColor tintColor]];
}

- (void)normalizeTint {
    [[self selectedBackgroundView] setBackgroundColor:[UIColor tintColor]];
    [[self labelTitle] setTextColor:[UIColor whiteColor]];
}

@end
