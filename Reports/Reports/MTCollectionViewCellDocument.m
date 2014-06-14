//
//  MTCollectionViewCellDocument.m
//  Reports
//
//  Created by Michael Thomason on 2/19/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

NSString * const MTImageBlank                               = @"UIImageDocumentBlank";

#import "MTCollectionViewCellDocument.h"
#import "UIDevice+Hack.h"
#import <QuartzCore/QuartzCore.h>
#import "UIColor+EverydayApps.h"
#import "MADocument.h"
#import "MAReportDocument.h"

@interface MTCollectionViewCellDocument ()
@property (nonatomic, strong) UIColor *bgColor;
@end

@implementation MTCollectionViewCellDocument

- (void)awakeFromNib {
    CGFloat offset = 2.0000f * [[UIScreen mainScreen] scale];
    
    [[[self imagePreview] layer] setShadowColor:[[UIColor darkGrayColor] CGColor]];
    [[[self imagePreview] layer] setShadowRadius:2.0000f];
    [[[self imagePreview] layer] setShadowOpacity:1.0000f];
    CGSize offsetSize = CGSizeMake(offset, offset);
    [[[self imagePreview] layer] setShadowOffset:offsetSize];

    [[self labelTitle] setTextColor:[UIColor tintColorBlue]];
    [[self labelTitle] setClipsToBounds:NO];
    
    [[[self selectedBackgroundView] layer] setCornerRadius:5.0000f];
    
    [[self imagePreview] setContentMode:UIViewContentModeScaleAspectFit];
    
    [super awakeFromNib];
}

- (void)performSelectionAnimations {
    [[self labelTitle] setTextColor:[UIColor whiteColor]];
}

- (void)performDeselectionAnimations {
    [[self labelTitle] setTextColor:[UIColor tintColorBlue]];
}

- (void)configureCellForUrl:(NSURL *)url {
    [self setText: [MADocument fileNameForMadUrl:url]];
    [self loadPreviewImageForUrl:url];
}

- (void)loadPreviewImageForUrl:(NSURL *)url {
    __weak MTCollectionViewCellDocument *weakself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        dispatch_sync(dispatch_get_main_queue(), ^(void) {
            NSURL *thumbnailUrl = [MAReportDocument thumbnailUrlForMadUrl:url];
            NSString *path = [thumbnailUrl path];
            UIImage *image = [[UIImage alloc] initWithContentsOfFile:path];
            if (image) {
                [[weakself imagePreview] setImage: image];
            } else {
                UIImage *defaultThumbnail = [UIImage imageNamed:MTImageBlank];
                [[weakself imagePreview] setImage: defaultThumbnail];
            }
            [weakself setNeedsLayout];
        });
    });
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
    [[self labelTitle] setAttributedText:attributedString];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        UIColor *bgColor = [[UIColor tintColorBlue] colorWithAlphaComponent:0.70000f];
        [self setBgColor:bgColor];
        
        UIView *selectedBackground = [[UIView alloc] initWithFrame:[self frame]];
        if ([UIDevice isLagacyOS]) {
            [[selectedBackground layer] setCornerRadius: 1.0000f];
        }
        [selectedBackground setClipsToBounds:YES];
        if ([UIDevice isModernOS]) {
            [selectedBackground setBackgroundColor:[self bgColor]];
        }
        
        [self setSelectedBackgroundView:selectedBackground];
    }
    return self;
}



- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return action == @selector(email:) || action == @selector(delete:) || action == @selector(rename:) || action == @selector(duplicate:);
}

- (BOOL)resignFirstResponder {
    [[self labelTitle] setTextColor:[UIColor tintColorBlue]];
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

- (void)duplicate:(id)sender {
    [[self delegate] duplicate:self];
}

- (void)dimTint {
    [[self selectedBackgroundView] setBackgroundColor:[UIColor lightGrayColor]];
    [[self labelTitle] setTextColor:[UIColor darkGrayColor]];
}

- (void)normalizeTint {
    [[self selectedBackgroundView] setBackgroundColor:[self bgColor]];
    [[self labelTitle] setTextColor:[UIColor whiteColor]];
}

@end
