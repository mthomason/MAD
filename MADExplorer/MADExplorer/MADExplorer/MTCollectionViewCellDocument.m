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
#import "NSAttributedString+FileExplorer.h"

#import <QuartzCore/CALayer.h>

#import <UIKit/UINibLoading.h>
#import <UIKit/NSAttributedString.h>
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

static const CGFloat Float_0                    =   0.00000000f;
static const CGFloat Float_100                  = 100.00000000f;

float wobbleFactor(void);
float wobbleFactor() {
    return (arc4random_uniform(500) / 500.0000f) + 0.5000f;
}

@interface MADCollectionViewCellDocument () {
    bool _wobbling;
  @protected
    UIView * _selectedBackgroundView;
}

    @property (nonatomic, readwrite, copy) UIColor *colorTextNormal;
    @property (nonatomic, readwrite, copy) UIColor *colorTextSelected;

    @property (nonatomic, readwrite, weak) UIActivityIndicatorView *activityIndicator;

@end

@implementation MADCollectionViewCellDocument

- (UIView *)selectedBackgroundView {
    if (_selectedBackgroundView == nil) {
        _selectedBackgroundView = [[MADBackgroundViewSelected alloc] initWithFrame:self.contentView.frame];
        self.selectedBackgroundView = _selectedBackgroundView;
    }
    return _selectedBackgroundView;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    _labelTitle.textColor = selected ? _colorTextSelected.copy : _colorTextNormal.copy;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted: highlighted];
    _labelTitle.textColor = highlighted   ? [UIColor whiteColor] :
                            self.selected ? _colorTextSelected.copy : _colorTextNormal.copy;
}

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

- (void)awakeFromNib {
    
    _wobbling = false;
    
    self.colorTextSelected = [UIColor lightTextColor];
    
    UIColor *colorTextNormal = [MADColorEverydayApps newColorBlue];
    self.colorTextNormal = colorTextNormal.copy;
    
    self.contentView.autoresizingMask = MADViewAutoresizingFlexable();
    self.contentView.translatesAutoresizingMaskIntoConstraints = YES;
    
    UIColor *clearColor = [UIColor clearColor];
    UIColor *lightGrayColor = [UIColor lightGrayColor];
    
    self.labelTitle.userInteractionEnabled = YES;
    
    self.labelTitle.textColor = self.colorTextNormal.copy;
    self.labelTitle.clipsToBounds = NO;
    self.labelTitle.numberOfLines = 0;
    self.labelTitle.backgroundColor = clearColor;
    
    UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    self.labelTitle.font = font;
    
    self.labelTitleSub.textColor = lightGrayColor;
    self.labelTitleSub.clipsToBounds = NO;
    self.labelTitleSub.numberOfLines = 0;
    self.labelTitleSub.backgroundColor = clearColor;
    
    font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
    self.labelTitleSub.font = font;

    self.imagePreview.contentMode = UIViewContentModeScaleAspectFit;
    
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

    NSString *string = text.copy;
    id attributedString = [NSAttributedString newAttributedStringCaptionWithText:string];

    UILabel *labelTitle = _labelTitle;
    labelTitle.attributedText = attributedString;
    labelTitle.text = string;
}

- (void)updateFont {
    NSString *text = self.labelTitle.text.copy;
    [self setText: text];
}

- (void)startWobble {
    if (_wobbling) return;
    
    _wobbling = true;
    float r = wobbleFactor();
    
    self.layer.anchorPoint = CGPointMake(0.5, 0.5);
    
    void (^animationFinish)(void);
    void (^animationStart)(void);
    void (^ animationStartCompletion)(BOOL finished);
    
    
    MADCollectionViewCellDocument __weak *weakself = self;
    
    animationFinish = ^(void){
        [UIView setAnimationRepeatCount: MAXFLOAT];
        MADCollectionViewCellDocument *strongself = weakself;
        if (strongself) {
            CGAffineTransform rightWobble;
            rightWobble = CGAffineTransformMakeRotation(
                                    (CGFloat)degreesToRadians(kAnimationRotateDeg + r ));
            strongself.transform = rightWobble;
        }
    };
    
    animationStart = ^{
        MADCollectionViewCellDocument *strongself = weakself;
        if (strongself) {
            CGAffineTransform leftWobble;
            leftWobble = CGAffineTransformMakeRotation(
                                    (CGFloat)degreesToRadians((kAnimationRotateDeg * -1.0) - r));
            strongself.transform = leftWobble;
        }
    };
    
    animationStartCompletion = ^(BOOL finished) {
        
        [UIView animateWithDuration: 0.2
                              delay: 0
                            options: UIViewAnimationOptionAllowUserInteraction |
         UIViewAnimationOptionRepeat |
         UIViewAnimationOptionAutoreverse |
         UIViewAnimationOptionBeginFromCurrentState
                         animations: animationFinish
                         completion: nil];
    };
    
    [UIView animateWithDuration: 0.2
                     animations: animationStart
                     completion: animationStartCompletion];
}

- (void)stopWobble {
    if (_wobbling) {
        _wobbling = false;
        [self.layer removeAllAnimations];
        self.transform = CGAffineTransformIdentity;
    }
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
    NSString *label = [[NSString alloc] initWithFormat: documentName, _labelTitle.text];
    return label;
}

- (NSInteger)accessibilityElementCount {
    return 2;
}

- (NSInteger)indexOfAccessibilityElement:(id)element {
    return [element isKindOfClass:[UIImageView class]] ? 0 : 1;
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

- (void)setUploadingActive:(BOOL)active
                   percent:(double)percent {
    [self updateProgressView: _progressViewUpload
                      active: active
                     percent: percent];

}

- (void)setDownloadingActive:(BOOL)active
                     percent:(double)percent {
    [self updateProgressView: _progressViewDownload
                      active: active
                     percent: percent];
    
}

- (void)updateProgressView:(UIProgressView *)progressView
                    active:(BOOL)active
                   percent:(double)percent {
    
    if (!active) {
        progressView.hidden = YES;
        [progressView setProgress:Float_0 animated:YES];
        return;
    }
    
    progressView.hidden = NO;
    if (progressView.progress < percent / Float_100) {
        [progressView setProgress: (float) (percent / Float_100)
                         animated: YES];
    }
}

@end
