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
#import "MTDocumentCellProtocol.h"

#import <QuartzCore/CALayer.h>

#import <UIKit/UINibLoading.h>
#import <UIKit/NSAttributedString.h>
#import <UIKit/UITapGestureRecognizer.h>
#import <UIKit/UILongPressGestureRecognizer.h>
#import <UIKit/UIProgressView.h>
#import <UIKit/UIActivityIndicatorView.h>
#import <UIKit/UIImage.h>
#import <UIKit/UIImageView.h>
#import <UIKit/UILabel.h>
#import <UIKit/UIAccessibility.h>

#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADCocoaExtensions/UIView+Animations.h>

#import "MADBackgroundViewSelected.h"

NSString * const MTImageBlank = @"UIImageDocumentBlank";

#define degreesToRadians(x) (M_PI * (x) / 180.0)
const CGFloat MTAnimationRotateDeg = 1.0000f;
#define degreesToRadians(x) (M_PI * (x) / 180.0)
#define kAnimationRotateDeg 1.0

@interface MADCollectionViewCellDocument ()

    @property (nonatomic, readwrite, weak) UIActivityIndicatorView *activityIndicator;

    @property (nonatomic, readwrite, copy) UIColor *colorTextNormal;
    @property (nonatomic, readwrite, copy) UIColor *colorTextSelected;

    @property (nonatomic, readwrite, weak) UILongPressGestureRecognizer *longPressGestureRecognizer;
    @property (nonatomic, readwrite, weak) UITapGestureRecognizer *tapGestureRecognizer;

    @property (nonatomic, readwrite, assign) BOOL wobbling;
    @property (nonatomic, readwrite, assign) BOOL addedGestures;

@end

@implementation MADCollectionViewCellDocument

+ (UIActivityIndicatorView *)newActivityIndicatorView {
    
    UIActivityIndicatorView *activityIndicatorView;
    activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:
                                                                UIActivityIndicatorViewStyleGray];
    [activityIndicatorView stopAnimating];
    activityIndicatorView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
                                                UIViewAutoresizingFlexibleRightMargin |
                                                UIViewAutoresizingFlexibleTopMargin |
                                                UIViewAutoresizingFlexibleBottomMargin;
    activityIndicatorView.translatesAutoresizingMaskIntoConstraints = YES;
    return activityIndicatorView;
}


- (void)prepareForReuse {
    [super prepareForReuse];
    UIImage *result = [UIImage imageNamed:MTImageBlank];
    self.imagePreview.image = result;
}

+ (UIImage *)newDefaultThumbnail {
    UIImage *result = [UIImage imageNamed:MTImageBlank];
    return result;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self commonInitWithFrame:self.frame];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commonInitWithFrame:frame];
    }
    return self;
}

- (instancetype)init {
    if (self = [super init]) {
        [self commonInitWithFrame:self.frame];
    }
    return self;
}

- (void)commonInitWithFrame:(CGRect)frame {
    _addedGestures = NO;
    UIView *selectedBackground = [[MADBackgroundViewSelected alloc] initWithFrame:frame];
    self.selectedBackgroundView = selectedBackground;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
}

- (void)awakeFromNib {
    
    _wobbling = NO;
    
    UIColor *colorTextSelected = [UIColor lightTextColor];
    self.colorTextSelected = colorTextSelected.copy;
    
    UIColor *colorTextNormal = [MADColorEverydayApps newColorBlue];
    self.colorTextNormal = colorTextNormal.copy;
    
    self.contentView.autoresizingMask = MADViewAutoresizingFlexable();
    self.contentView.translatesAutoresizingMaskIntoConstraints = YES;
    
    //UIColor *color = [UIColor darkGrayColor];
    UIColor *clearColor = [UIColor clearColor];
    UIColor *lightGrayColor = [UIColor lightGrayColor];

    if (!_addedGestures) {
        SEL actionEdit = @selector(actionActivateEditMode:);
        BOOL gotActionEdit = NO, gotActionRename = NO;
        SEL actionRename = @selector(actionRename:);
        for (UIGestureRecognizer *gestureRecognizer in  self.gestureRecognizers) {
            if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) gotActionEdit = YES;
            if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) gotActionRename = YES;
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
        _addedGestures = YES;
    }
    
    /*
    self.imagePreview.layer.shadowColor = color.CGColor;
    self.imagePreview.layer.shadowRadius = 2.0000f;
    self.imagePreview.layer.shadowOpacity = 0.4500f;
    self.imagePreview.layer.shadowOffset = CGSizeMake(1.0f, 1.0f);
    */
    
    self.labelTitle.userInteractionEnabled = YES;
    
    self.labelTitle.textColor = self.colorTextNormal.copy;
    self.labelTitle.clipsToBounds = NO;
    self.labelTitle.numberOfLines = 0;
    self.labelTitle.backgroundColor = clearColor;
    
    UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    self.labelTitle.font = font;
    //[self.labelTitle setNeedsLayout];
    
    self.labelTitleSub.textColor = lightGrayColor;
    self.labelTitleSub.clipsToBounds = NO;
    self.labelTitleSub.numberOfLines = 0;
    self.labelTitleSub.backgroundColor = clearColor;
    
    font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
    self.labelTitleSub.font = font;
    //[self.labelTitleSub setNeedsLayout];

    self.imagePreview.contentMode = UIViewContentModeScaleAspectFit;

    [self normalizeTint];
    
    [super awakeFromNib];
}

- (UIActivityIndicatorView *)activityIndicator {
    UIActivityIndicatorView *result = _activityIndicator;
    if (result == nil) {
        result = [MADCollectionViewCellDocument newActivityIndicatorView];
        result.center = self.contentView.center;
        [self.contentView addSubview:result];
        _activityIndicator = result;
    }
    return result;
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
    [_labelTitle setNeedsLayout];
    [_labelTitleSub setNeedsLayout];
}


- (void)setBounds:(CGRect)bounds {
    super.bounds = bounds;
    self.contentView.frame = bounds;
}

- (void)setText:(NSString *)text {

    NSDictionary *attributes = [MADCollectionViewCellDocument newAttributesCaption];
    NSMutableAttributedString *attributedString;
    attributedString = [[NSMutableAttributedString alloc] initWithString: text
                                                              attributes: attributes];
    UILabel *labelTitle = _labelTitle;
    labelTitle.attributedText = attributedString;
    labelTitle.text = text.copy;
}

+ (NSDictionary *)newAttributesCaption {
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.baseWritingDirection = NSWritingDirectionLeftToRight;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    
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
    
    UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
    id attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                                [NSNull null], NSKernAttributeName,
                                font, NSFontAttributeName,
                                paragraphStyle, NSParagraphStyleAttributeName, nil];
    return attributes;
}

- (void)updateFont {
    NSString *text = self.labelTitle.text.copy;
    [self setText: text];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return action == @selector(actionEmail:) ||
           action == @selector(delete:) ||
           action == @selector(actionRename:) ||
           action == @selector(duplicate:);
}

- (BOOL)becomeFirstResponder {
    return YES;
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)actionEmail:(id)sender {
    [_delegate actionEmail:self];
}

- (void)actionActivateEditMode:(id)sender {
    [_delegate actionActivateEditMode:sender];
}

- (void)actionRename:(id)sender {
    [_delegate actionRename:self];
}

- (void)duplicate:(id)sender {
    [_delegate actionDuplicate:self];
}

- (void)normalizeTint {
    UITapGestureRecognizer __unsafe_unretained * tapGestureRecognizer = _tapGestureRecognizer;
    UILabel                __unsafe_unretained * labelTitle           = _labelTitle;
    if (self.highlighted) {
        id colorTextSelectedHighlighted = [UIColor whiteColor];
        labelTitle.textColor = colorTextSelectedHighlighted;
    } else if (self.selected) {
        labelTitle.textColor = _colorTextSelected.copy;
        tapGestureRecognizer.enabled = NO;
    } else {
        labelTitle.textColor = _colorTextNormal.copy;
        tapGestureRecognizer.enabled = YES;
    }
}

- (void)startWobble {
    if (self.wobbling == NO) {
        self.wobbling = YES;
        u_int32_t randomInt = arc4random_uniform(500);
        float r = (randomInt / 500.0000f) + 0.5000f;
        CGAffineTransform leftWobble, rightWobble;
        leftWobble = CGAffineTransformMakeRotation((CGFloat)degreesToRadians((kAnimationRotateDeg * -1.0) - r));
        rightWobble = CGAffineTransformMakeRotation((CGFloat)degreesToRadians( kAnimationRotateDeg + r ));
        
        self.layer.anchorPoint = CGPointMake(0.5, 0.5);
        MADCollectionViewCellDocument __weak *weakself = self;
        [UIView animateWithDuration:0.2 animations:^{
            MADCollectionViewCellDocument *strongself = weakself;
            if (strongself) {
                strongself.transform = leftWobble;
            }
        } completion:^(BOOL finished) {
            MADCollectionViewCellDocument *strongself = weakself;
            if (strongself) {
                MADCollectionViewCellDocument __weak *weakself2 = strongself;
                [UIView animateWithDuration:0.2
                                      delay:0
                                    options:UIViewAnimationOptionAllowUserInteraction |
                                            UIViewAnimationOptionRepeat |
                                            UIViewAnimationOptionAutoreverse |
                                            UIViewAnimationOptionBeginFromCurrentState
                                 animations:^{
                                     [UIView setAnimationRepeatCount: MAXFLOAT];
                                     MADCollectionViewCellDocument *strongself2 = weakself2;
                                     if (strongself2) {
                                         strongself2.transform = rightWobble;
                                     }
                                 }
                                 completion:nil];
            }
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
    NSString *documentHint = _wobbling ? NSLocalizedString(@"Selects document named %@.",
                                                           @"Selects document named %@.") :
                                         NSLocalizedString(@"Opens document named %@.",
                                                           @"Opens document named %@.");
    return [NSString stringWithFormat: documentHint, _labelTitle.text];
}

- (NSString *)accessibilityLabel {
    NSString *documentName = NSLocalizedString(@"Document %@", @"Document %@");
    return [NSString stringWithFormat: documentName, _labelTitle.text];
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
            NSString *documentHint = _wobbling ? NSLocalizedString(@"Selects document named %@.",
                                                                   @"Selects document named %@.") :
                                                 NSLocalizedString(@"Opens document named %@.",
                                                                   @"Opens document named %@.");
            UIImageView *imagePreview = _imagePreview;
            UILabel *labelTitle = _labelTitle;
            NSString *documentName = NSLocalizedString(@"Document %@", @"Document %@");
            imagePreview.isAccessibilityElement = YES;
            NSString *text;
            
            text = [[NSString alloc] initWithFormat: documentHint, labelTitle.text];
            imagePreview.accessibilityHint = text;
            
            text = [[NSString alloc] initWithFormat: documentName, labelTitle.text];
            imagePreview.accessibilityLabel = text;
            
            imagePreview.accessibilityTraits = UIAccessibilityTraitButton;
            return imagePreview;
            break;
        }
        case 1: {
            NSString *documentName = NSLocalizedString(@"Document %@", @"Document %@");
            UILabel *labelTitle = _labelTitle;
            NSString *text;
            labelTitle.isAccessibilityElement = YES;
            text = [[NSString alloc] initWithFormat: documentName, labelTitle.text];
            labelTitle.accessibilityLabel = text;
            labelTitle.accessibilityHint = NSLocalizedString(@"Renames document.",
                                                             @"Renames document.");;
            labelTitle.accessibilityTraits = UIAccessibilityTraitButton;
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
