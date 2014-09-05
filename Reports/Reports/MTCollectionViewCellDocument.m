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

NSString * const MTImageBlank = @"UIImageDocumentBlank";

#import "MTCollectionViewCellDocument.h"
#import "UIDevice+Hack.h"
#import <QuartzCore/QuartzCore.h>
#import "UIColor+EverydayApps.h"
#import "MADocument.h"

@interface MTCollectionViewCellDocument ()

@property (nonatomic, strong) UIColor *bgColor;
@property (nonatomic, strong) NSParagraphStyle *paragraphStyle;

@end

@implementation MTCollectionViewCellDocument

- (void)awakeFromNib {
    CGFloat offset = 2.0000f * [[UIScreen mainScreen] scale];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    paragraphStyle.baseWritingDirection = NSWritingDirectionLeftToRight;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    self.paragraphStyle = paragraphStyle;
    
    self.imagePreview.layer.shadowColor = [UIColor darkGrayColor].CGColor;
    self.imagePreview.layer.shadowRadius = 2.0000f;
    self.imagePreview.layer.shadowOpacity = 1.0000f;
    self.imagePreview.layer.shadowOffset = CGSizeMake(offset, offset);

    self.labelTitle.textColor = [UIColor tintColorBlue];
    self.labelTitle.clipsToBounds = NO;
    
    self.selectedBackgroundView.layer.cornerRadius = 5.0000f;
    
    self.imagePreview.contentMode = UIViewContentModeScaleAspectFit;
    
    [super awakeFromNib];
}

- (void)performSelectionAnimations {
    self.labelTitle.textColor = [UIColor whiteColor];
}

- (void)performDeselectionAnimations {
    self.labelTitle.textColor = [UIColor tintColorBlue];
}

- (void)configureCellForUrl:(NSURL *)url {
    self.text = [MADocument fileNameForMadUrl:url];
    [self loadPreviewImageForUrl:url];
}

- (void)loadPreviewImageForUrl:(NSURL *)url {
    __weak MTCollectionViewCellDocument *weakself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void) {
        dispatch_sync(dispatch_get_main_queue(), ^(void) {
            NSURL *thumbnailUrl = [MADocument thumbnailUrlForMadUrl:url];
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
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text];
    NSInteger length = [[attributedString string] length];
    CGFloat size = [UIDevice isPad] ? 22.0000f : 12.0000f;
    UIFont *fonta = [UIFont systemFontOfSize:size];
    NSRange range = NSMakeRange(0, length);
    [attributedString addAttribute:NSKernAttributeName value:[NSNull null] range:range];
    [attributedString addAttribute:NSFontAttributeName value:fonta range:range];
    [attributedString addAttribute:NSParagraphStyleAttributeName value:self.paragraphStyle range:range];
    [self.labelTitle setAttributedText:attributedString];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        UIColor *bgColor = [[UIColor tintColorBlue] colorWithAlphaComponent:0.70000f];
        [self setBgColor:bgColor];
        
        UIView *selectedBackground = [[UIView alloc] initWithFrame:[self frame]];
        //[selectedBackground layer].cornerRadius =  1.0000f;
        [selectedBackground setClipsToBounds:YES];
        selectedBackground.backgroundColor = [self bgColor];
        
        [self setSelectedBackgroundView:selectedBackground];
        
        UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [activityView stopAnimating];
        activityView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        [activityView setCenter:[[self contentView] center]];
        [self.contentView addSubview:activityView];
        [self setActivityIndicator:activityView];
        
    }
    return self;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return action == @selector(email:) || action == @selector(delete:) || action == @selector(rename:) || action == @selector(duplicate:);
}

- (BOOL)resignFirstResponder {
    self.labelTitle.textColor = [UIColor tintColorBlue];
    return YES;
}

- (BOOL)becomeFirstResponder {
    self.labelTitle.textColor = [UIColor whiteColor];
    return YES;
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)delete:(id)sender {
    [self.delegate deleteDocumentRepresentedByCell:self];
}

- (void)email:(id)sender {
    [self.delegate email:self];
}

- (void)rename:(id)sender {
    [self.delegate rename:self];
}

- (void)duplicate:(id)sender {
    [self.delegate duplicate:self];
}

- (void)dimTint {
    self.selectedBackgroundView.backgroundColor = [UIColor lightGrayColor];
    self.labelTitle.textColor = [UIColor darkGrayColor];
}

- (void)normalizeTint {
    self.selectedBackgroundView.backgroundColor = [self bgColor];
    self.labelTitle.textColor = [UIColor whiteColor];
}

@end
