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
@property (nonatomic, strong) UIColor *colorTextNormal;
@property (nonatomic, strong) UIColor *colorTextSelectedHighlighted;
@property (nonatomic, strong) UIColor *colorTextSelected;

@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;

@end

@implementation MTCollectionViewCellDocument

+ (UIFont *)CaptionFont {
    return [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
}

+ (UIFont *)CaptionFont2 {
    return [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
}

- (void)awakeFromNib {
    
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.contentView.translatesAutoresizingMaskIntoConstraints = YES;
    
    CGFloat offset = 2.0000f * [[UIScreen mainScreen] scale];
    
    self.imagePreview.layer.shadowColor = [UIColor darkGrayColor].CGColor;
    self.imagePreview.layer.shadowRadius = 2.0000f;
    self.imagePreview.layer.shadowOpacity = 1.0000f;
    self.imagePreview.layer.shadowOffset = CGSizeMake(offset, offset);

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget: self
                                                                          action: @selector(rename:)];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;
    self.tapGestureRecognizer = tap;
    
    [self.labelTitle addGestureRecognizer:tap];
    self.labelTitle.userInteractionEnabled = YES;

    self.labelTitle.textColor = self.colorTextNormal;
    self.labelTitle.clipsToBounds = NO;
    self.labelTitle.numberOfLines = 0;
    self.labelTitle.backgroundColor = [UIColor clearColor];
    self.labelTitle.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    [self.labelTitle setNeedsLayout];
    
    self.labelTitleSub.textColor = [UIColor lightGrayColor];
    self.labelTitleSub.clipsToBounds = NO;
    self.labelTitleSub.numberOfLines = 0;
    self.labelTitleSub.backgroundColor = [UIColor clearColor];
    self.labelTitleSub.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
    [self.labelTitleSub setNeedsLayout];

    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget: self
                                                                                                             action: @selector(activateEditMode:)];
    [self addGestureRecognizer: longPressGestureRecognizer];
    self.longPressGestureRecognizer = longPressGestureRecognizer;

    
    self.selectedBackgroundView.backgroundColor = self.bgColor;
    self.selectedBackgroundView.clipsToBounds = YES;
    self.selectedBackgroundView.layer.cornerRadius = 5.0000f;

    self.imagePreview.contentMode = UIViewContentModeScaleAspectFit;

    [self normalizeTint];
    
    [super awakeFromNib];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        
        UIColor *colorTextNormal = [UIColor tintColorBlue];
        UIColor *bgColor = [colorTextNormal colorWithAlphaComponent:0.70000f];
        self.bgColor = bgColor;
        
        UIView *selectedBackground = [[UIView alloc] initWithFrame:self.frame];
        self.selectedBackgroundView = selectedBackground;
        
        UIActivityIndicatorView *activityView = [MTCollectionViewCellDocument activityIndicatorView];
        activityView.center = self.contentView.center;
        [self.contentView addSubview:activityView];

        UIColor *colorTextSelectedHighlighted = [UIColor whiteColor];
        UIColor *colorTextSelected = [UIColor lightTextColor];
        self.colorTextSelectedHighlighted = colorTextSelectedHighlighted;
        self.colorTextSelected = colorTextSelected;
        self.activityIndicator = activityView;
        self.colorTextNormal = colorTextNormal;
        
        self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
        
    }
    return self;
}

+ (UIActivityIndicatorView *)activityIndicatorView {

    UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleGray];
    [activityIndicatorView stopAnimating];
    activityIndicatorView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
                                                UIViewAutoresizingFlexibleRightMargin |
                                                UIViewAutoresizingFlexibleTopMargin |
                                                UIViewAutoresizingFlexibleBottomMargin;
    activityIndicatorView.translatesAutoresizingMaskIntoConstraints = YES;
    return activityIndicatorView;
}

- (void)setDelegate:(id<MTDocumentCellProtocol, UIGestureRecognizerDelegate>)delegate {
    if (_delegate != delegate) {
        self.longPressGestureRecognizer.delegate = delegate;
        _delegate = delegate;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

- (void)performSelectionAnimations {
    [self normalizeTint];
}

- (void)performDeselectionAnimations {
    [self normalizeTint];
}

/*- (void)configureCellForUrl:(NSURL *)url {
    self.text = [MADocument fileNameForMadUrl:url];
    self.labelTitle.text = [MADocument fileNameForMadUrl:url];
    [self loadPreviewImageForUrl:url];
}*/

- (void)loadPreviewImageForUrl:(NSURL *)url {
    NSURL *thumbnailUrl = [MADocument thumbnailUrlForMadUrl:url];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:thumbnailUrl.path];
    if ([NSThread isMainThread]) {
        [self updatePreviewImageUIForImage:image];
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^(void) {
            [self updatePreviewImageUIForImage:image];
        });
    }
}

- (void)updatePreviewImageUIForImage:(UIImage *)image {
    self.imagePreview.image = image ?: [UIImage imageNamed:MTImageBlank];
    [self setNeedsLayout];
}

- (void)setNeedsLayout {
    [super setNeedsLayout];
    [self.labelTitle setNeedsLayout];
    [self.labelTitleSub setNeedsLayout];
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    self.contentView.frame = bounds;
}

- (void)setText:(NSString *)text {

    NSDictionary *attributes = [MTCollectionViewCellDocument attributesCaption];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString: text
                                                                                         attributes: attributes];
    self.labelTitle.attributedText = attributedString;
    self.labelTitle.text = text;
}

+ (NSDictionary *)attributesCaption {
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.baseWritingDirection = NSWritingDirectionLeftToRight;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    UIFont *font = [self CaptionFont];
    NSDictionary *attributes = @{NSKernAttributeName : [NSNull null],
                                 NSFontAttributeName : font,
                                 NSParagraphStyleAttributeName : paragraphStyle};
    return attributes;
}

+ (NSDictionary *)attributesCaption2 {
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.baseWritingDirection = NSWritingDirectionLeftToRight;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    UIFont *font = [self CaptionFont2];
    NSDictionary *attributes = @{NSKernAttributeName : [NSNull null],
                                 NSFontAttributeName : font,
                                 NSParagraphStyleAttributeName : paragraphStyle};
    return attributes;
}

- (void)updateFont {
    [self setText:self.labelTitle.text];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return action == @selector(email:) ||
           action == @selector(delete:) ||
           action == @selector(rename:) ||
           action == @selector(duplicate:);
}

- (BOOL)resignFirstResponder {
    return YES;
}

- (BOOL)becomeFirstResponder {
    return YES;
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)email:(id)sender {
    [self.delegate email:self];
}

- (void)activateEditMode:(id)sender {
    [self.delegate activateEditMode:sender];
}

- (void)rename:(id)sender {
    [self.delegate rename:self];
}

- (void)duplicate:(id)sender {
    [self.delegate duplicate:self];
}

- (void)normalizeTint {
    if (self.highlighted) {
        self.labelTitle.textColor = self.colorTextSelectedHighlighted;
    } else if (self.selected) {
        self.labelTitle.textColor = self.colorTextSelected;
        self.tapGestureRecognizer.enabled = NO;
    } else {
        self.labelTitle.textColor = self.colorTextNormal;
        self.tapGestureRecognizer.enabled = YES;
    }
}

@end
