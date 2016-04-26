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

#import "MTCollectionViewCellDocument.h"
#import "MADBackgroundViewSelected.h"
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADCocoaExtensions/UIView+Animations.h>

NSString * const MTImageBlank = @"UIImageDocumentBlank";

#define degreesToRadians(x) (M_PI * (x) / 180.0)
const CGFloat MTAnimationRotateDeg = 1.0000f;
#define degreesToRadians(x) (M_PI * (x) / 180.0)
#define kAnimationRotateDeg 1.0

@interface MTCollectionViewCellDocument ()

    @property (nonatomic, strong) UIColor *colorTextNormal;
    @property (nonatomic, strong) UIColor *colorTextSelected;

    @property (nonatomic, weak) UILongPressGestureRecognizer *longPressGestureRecognizer;
    @property (nonatomic, weak) UITapGestureRecognizer *tapGestureRecognizer;

    @property (nonatomic, strong) UIMotionEffectGroup *hoverEffects;

    @property (nonatomic, assign) BOOL wobbling;

@end

@implementation MTCollectionViewCellDocument

+ (UIImage *)newDefaultThumbnail {
    UIImage *result = [UIImage imageNamed:MTImageBlank];
    return result;
}

+ (UIFont *)newCaptionFont {
    UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    return font;
}

+ (UIFont *)newCaptionFont2 {
    UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
    return font;
}

- (void)awakeFromNib {
    //NSLog(@"\t%s", __PRETTY_FUNCTION__);
    
    self.wobbling = NO;
    
    UIView *selectedBackground = [[MADBackgroundViewSelected alloc] initWithFrame:self.frame];
    self.selectedBackgroundView = selectedBackground;
    
    UIColor *colorTextSelected = [UIColor lightTextColor];
    self.colorTextSelected = colorTextSelected;
    
    UIColor *colorTextNormal = [MADColorEverydayApps newColorBlue];
    self.colorTextNormal = colorTextNormal;
    
    self.contentView.autoresizingMask = MADViewAutoresizingFlexable();
    self.contentView.translatesAutoresizingMaskIntoConstraints = YES;
    
    UIColor *color = [UIColor darkGrayColor];
    UIColor *clearColor = [UIColor clearColor];
    UIColor *lightGrayColor = [UIColor lightGrayColor];

    self.imagePreview.layer.shadowColor = color.CGColor;
    self.imagePreview.layer.shadowRadius = 2.0000f;
    self.imagePreview.layer.shadowOpacity = 0.4500f;
    self.imagePreview.layer.shadowOffset = CGSizeMake(1.0f, 1.0f);
    
    self.labelTitle.userInteractionEnabled = YES;

    SEL actionEdit = @selector(activateEditMode:);
    bool gotActionEdit = false, gotActionRename = false;
    SEL actionRename = @selector(rename:);
    for (UIGestureRecognizer *gestureRecognizer in  self.gestureRecognizers) {
        if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) gotActionEdit = true;
        if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) gotActionRename = true;
        if (gotActionEdit && gotActionRename) break;
    }
    
    if (!gotActionEdit) {
        id longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget: self
                                                                            action: actionEdit];
        [self addGestureRecognizer: longPressGesture];
        self.longPressGestureRecognizer = longPressGesture;
    }
    
    if (!gotActionRename) {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget: self
                                                                              action: actionRename];
        tap.numberOfTapsRequired = 1;
        tap.numberOfTouchesRequired = 1;
        
        [self.labelTitle addGestureRecognizer:tap];
        self.tapGestureRecognizer = tap;
    }
    
    self.labelTitle.textColor = self.colorTextNormal;
    self.labelTitle.clipsToBounds = NO;
    self.labelTitle.numberOfLines = 0;
    self.labelTitle.backgroundColor = clearColor;
    
    UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    self.labelTitle.font = font;
    [self.labelTitle setNeedsLayout];
    
    self.labelTitleSub.textColor = lightGrayColor;
    self.labelTitleSub.clipsToBounds = NO;
    self.labelTitleSub.numberOfLines = 0;
    self.labelTitleSub.backgroundColor = clearColor;
    
    font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
    self.labelTitleSub.font = font;
    [self.labelTitleSub setNeedsLayout];

    self.imagePreview.contentMode = UIViewContentModeScaleAspectFit;

    [self normalizeTint];
    
    [super awakeFromNib];
}

- (UIActivityIndicatorView *)activityIndicator {
    if (_activityIndicator == nil) {
        UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleGray];
        [activityView stopAnimating];
        activityView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
                                        UIViewAutoresizingFlexibleRightMargin |
                                        UIViewAutoresizingFlexibleTopMargin |
                                        UIViewAutoresizingFlexibleBottomMargin;
        activityView.translatesAutoresizingMaskIntoConstraints = YES;
        activityView.center = self.contentView.center;
        [self.contentView addSubview:activityView];
        _activityIndicator = activityView;
    }
    return _activityIndicator;
}

- (void)addMotionEffect:(UIMotionEffect *)effect {
    [self.imagePreview addMotionEffect:effect];
    [self.progressViewDownload addMotionEffect:effect];
    [self.progressViewUpload addMotionEffect:effect];
}

- (void)removeMotionEffect:(UIMotionEffect *)effect {
    [self.imagePreview removeMotionEffect:effect];
    [self.progressViewDownload removeMotionEffect:effect];
    [self.progressViewUpload removeMotionEffect:effect];
}

+ (UIActivityIndicatorView *)newActivityIndicatorView {

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

- (void)performSelectionAnimations {
    [self normalizeTint];
}

- (void)performDeselectionAnimations {
    [self normalizeTint];
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

    NSDictionary *attributes = [MTCollectionViewCellDocument newAttributesCaption];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString: text
                                                                                         attributes: attributes];
    self.labelTitle.attributedText = attributedString;
    self.labelTitle.text = text;
}

+ (NSDictionary *)newAttributesCaption {
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.baseWritingDirection = NSWritingDirectionLeftToRight;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    UIFont *font = [self newCaptionFont];
    
    id attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    [NSNull null], NSKernAttributeName,
                                    font, NSFontAttributeName,
                                    paragraphStyle, NSParagraphStyleAttributeName, nil];
    return attributes;
}

+ (NSDictionary *)newAttributesCaption2 {
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.baseWritingDirection = NSWritingDirectionLeftToRight;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    UIFont *font = [self newCaptionFont2];
    id attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                                [NSNull null], NSKernAttributeName,
                                font, NSFontAttributeName,
                                paragraphStyle, NSParagraphStyleAttributeName, nil];
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
    [self.delegate actionDuplicate:self];
}

- (void)normalizeTint {
    if (self.highlighted) {
        id colorTextSelectedHighlighted = [UIColor whiteColor];
        self.labelTitle.textColor = colorTextSelectedHighlighted;
    } else if (self.selected) {
        self.labelTitle.textColor = self.colorTextSelected;
        self.tapGestureRecognizer.enabled = NO;
    } else {
        self.labelTitle.textColor = self.colorTextNormal;
        self.tapGestureRecognizer.enabled = YES;
    }
}

- (void)startWobble {
    if (self.wobbling == NO) {
        self.wobbling = YES;
        u_int32_t randomInt = arc4random_uniform(500);
        float r = (randomInt / 500.0000f) + 0.5000f;
        CGAffineTransform leftWobble = CGAffineTransformMakeRotation((CGFloat)degreesToRadians((kAnimationRotateDeg * -1.0) - r));
        CGAffineTransform rightWobble = CGAffineTransformMakeRotation((CGFloat)degreesToRadians( kAnimationRotateDeg + r ));
        
        self.layer.anchorPoint = CGPointMake(0.5, 0.5);
        [UIView animateWithDuration:0.2 animations:^{
            self.transform = leftWobble;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.2
                                  delay:0
                                options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse | UIViewAnimationOptionBeginFromCurrentState
                             animations:^{
                                 [UIView setAnimationRepeatCount: MAXFLOAT];
                                 self.transform = rightWobble;
                             }
                             completion:nil];
        }];
    }
    
}

- (void)stopWobble {
    self.wobbling = NO;
    [self.layer removeAllAnimations];
    self.transform = CGAffineTransformIdentity;
}

-(BOOL)shouldGroupAccessibilityChildren{
    return YES;
}

- (BOOL)isAccessibilityElement {
    return NO;
}

- (NSString *)accessibilityHint {
    NSString *documentHint = self.wobbling ? NSLocalizedString(@"Selects document named %@.", @"Selects document named %@.") : NSLocalizedString(@"Opens document named %@.", @"Opens document named %@.");
    return [NSString stringWithFormat: documentHint, self.labelTitle.text];
}

- (NSString *)accessibilityLabel {
    NSString *documentName = NSLocalizedString(@"Document %@", @"Document %@");
    return [NSString stringWithFormat: documentName, self.labelTitle.text];
}

- (NSInteger)accessibilityElementCount {
    return 2;
}

- (NSInteger)indexOfAccessibilityElement:(id)element {
    if ([element isKindOfClass:[UIImageView class]]) {
        return 0;
    } else {
        return 1;
    }
}

- (id)accessibilityElementAtIndex:(NSInteger)index {
    switch (index) {
        case 0: {
            NSString *documentHint = self.wobbling ? NSLocalizedString(@"Selects document named %@.", @"Selects document named %@.") : NSLocalizedString(@"Opens document named %@.", @"Opens document named %@.");
            NSString *documentName = NSLocalizedString(@"Document %@", @"Document %@");
            self.imagePreview.isAccessibilityElement = YES;
            self.imagePreview.accessibilityHint = [NSString stringWithFormat: documentHint, self.labelTitle.text];
            self.imagePreview.accessibilityLabel = [NSString stringWithFormat: documentName, self.labelTitle.text];
            self.imagePreview.accessibilityTraits = UIAccessibilityTraitButton;
            return self.imagePreview;
            break;
        }
        case 1: {
            NSString *documentName = NSLocalizedString(@"Document %@", @"Document %@");
            self.labelTitle.isAccessibilityElement = YES;
            self.labelTitle.accessibilityLabel = [NSString stringWithFormat: documentName, self.labelTitle.text];
            self.labelTitle.accessibilityHint = NSLocalizedString(@"Renames document.", @"Renames document.");;
            self.labelTitle.accessibilityTraits = UIAccessibilityTraitButton;
            return self.labelTitle;
            break;
        }
        default:
            return nil;
            break;
    }
}

- (UIAccessibilityTraits)accessibilityTraits {
    return UIAccessibilityTraitButton;
}

@end
