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

#import "MADLabelFileExplorerDocumentCellTitle.h"
#import "MADLabelFileExplorerDocumentCellSubtitle.h"

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
#import <MADFileManager/MADMetaData.h>
#import <MADFoundation/NSURL+Document.h>

#import "MADBackgroundViewSelected.h"
#import "MADStandard.h"
#import "MADThumbnailView.h"

#define degreesToRadians(x) (M_PI * (x) / 180.0)
const CGFloat MTAnimationRotateDeg = 1.0000f;
#define degreesToRadians(x) (M_PI * (x) / 180.0)
#define kAnimationRotateDeg 1.0

static NSString * const MADTextHintDocumentWobblingYes  = @"Selects document named %@.";
static NSString * const MADTextHintDocumentWobblingNo   = @"Opens document named %@.";
static NSString * const MADTextDocumentName             = @"Document %@.";
static NSString * const MADTextRenamesDocument          = @"Renames document.";
       NSString * const MADTextNotDownloaded            = @"Not Downloaded";
static NSString * const Syncing                         = @"Syncing";
static NSString * const Downloading                     = @"Downloading";
static NSString * const MADImageToolbarCloudDownload    = @"MADImageToolbarCloudDownload";

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

    @property (nonatomic, readwrite, weak) UIActivityIndicatorView *activityIndicator;

@end

@implementation MADCollectionViewCellDocument

- (UIView *)selectedBackgroundView {
    if (_selectedBackgroundView == nil) {
        _selectedBackgroundView = [[MADBackgroundViewSelected alloc]
                                                initWithFrame:self.contentView.frame];
        self.selectedBackgroundView = _selectedBackgroundView;
    }
    return _selectedBackgroundView;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    [_labelTitle setSelected:selected];
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted: highlighted];
    [_labelTitle setHighlighted:highlighted];
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
    [self stopWobble];
    [self.imagePreview prepareForReuse];
}

- (void)awakeFromNib {
    
    _wobbling = false;
    
    self.contentView.autoresizingMask = MADViewAutoresizingFlexable();
    self.contentView.translatesAutoresizingMaskIntoConstraints = YES;
    
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
    void (^animationStartCompletion)(BOOL finished);
    
    
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

- (BOOL)shouldGroupAccessibilityChildren{
    return YES;
}

- (BOOL)isAccessibilityElement {
    return NO;
}

- (NSString *)accessibilityHint {
    NSString *documentHint = _wobbling ? NSLocalizedString(MADTextHintDocumentWobblingYes,
                                                           MADTextHintDocumentWobblingYes) :
                                         NSLocalizedString(MADTextHintDocumentWobblingNo,
                                                           MADTextHintDocumentWobblingNo);
    NSString *hint = [[NSString alloc] initWithFormat: documentHint, _labelTitle.text];
    return hint;
}

- (NSString *)accessibilityLabel {
    NSString *documentName = NSLocalizedString(MADTextDocumentName, MADTextDocumentName);
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
            NSString *documentHint = _wobbling ? NSLocalizedString(MADTextHintDocumentWobblingYes,
                                                                   MADTextHintDocumentWobblingYes) :
                                                 NSLocalizedString(MADTextHintDocumentWobblingNo,
                                                                   MADTextHintDocumentWobblingNo);
            UIImageView *imagePreview = _imagePreview;
            UILabel *labelTitle = _labelTitle;
            NSString *documentName = NSLocalizedString(MADTextDocumentName, MADTextDocumentName);
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
            NSString *documentName = NSLocalizedString(MADTextDocumentName,
                                                       MADTextDocumentName);
            UILabel *labelTitle = _labelTitle;
            NSString *text;
            labelTitle.isAccessibilityElement = YES;
            text = [[NSString alloc] initWithFormat: documentName, labelTitle.text];
            labelTitle.accessibilityLabel = text;
            labelTitle.accessibilityHint = NSLocalizedString(MADTextRenamesDocument,
                                                             MADTextRenamesDocument);
            labelTitle.accessibilityTraits = UIAccessibilityTraitButton;
            return self.labelTitle;
            break;
        }
        default:
            return nil;
            break;
    }
}

- (NSString *)titleLabelText {
    return _labelTitle.text;
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

- (void)updateDisplayForMetaData:(MADMetaData *)metadata editing:(BOOL)editing {
    
    _editing = editing;
    
    MADLabelFileExplorerDocumentCellTitle *labelTitle = _labelTitle;
    MADLabelFileExplorerDocumentCellSubtitle *labelTitleSub = _labelTitleSub;
    labelTitle.text = metadata.name.copy;
    BOOL notDownloaded  = [metadata.ubiquitousItemDownloadingStatus isEqualToString:
                           NSMetadataUbiquitousItemDownloadingStatusNotDownloaded],
    downloading    = metadata.ubiquitousItemIsDownloading,
    uploading      = metadata.ubiquitousItemIsUploading;
    
    id cellText;
    if (downloading) {
        cellText = NSLocalizedString(Downloading, Downloading);
        labelTitleSub.text = cellText;
    } else if (uploading) {
        cellText = NSLocalizedString(Syncing, Syncing);
        labelTitleSub.text = cellText;
    } else {
        NSString *subtitle = [self copySubtitleForStatus:metadata.ubiquitousItemDownloadingStatus
                                                fileSize:metadata.fileSystemFileSize];
        labelTitleSub.text = subtitle;
    }
    [self setUploadingActive:uploading percent:metadata.ubiquitousItemPercentUploaded];
    [self setDownloadingActive:downloading percent:metadata.ubiquitousItemPercentDownloaded];
    
    self.imageCloudIndicator.image = notDownloaded && metadata.isUbiquitous ?
                                        [UIImage imageNamed:MADImageToolbarCloudDownload] : nil;
    
    [labelTitle layoutIfNeeded];
    [labelTitleSub layoutIfNeeded];

    UIActivityIndicatorView *activityIndicator = _activityIndicator;
    if (metadata.ubiquitousItemIsDownloading || metadata.ubiquitousItemIsUploading)
        [activityIndicator startAnimating];
    else
        [activityIndicator stopAnimating];
    
    NSURL *thumbnailUrl = [NSURL newThumbnailUrlForMadUrl:metadata.URL];
    self.imagePreview.thumbnailURL = thumbnailUrl;
/*    dispatch_block_t read_iamge = ^{
        @autoreleasepool {
            //MADMetaData *thumbnailMetadata = [[MADMetaData alloc] initWithURL:fileURL];
            NSURL *thumbnailUrl = [NSURL newThumbnailUrlForMadUrl:fileURL];
            NSString *path = thumbnailUrl.path;
            NSData *imageData = [[NSData alloc] initWithContentsOfFile:path];
            UIImage *image = [[UIImage alloc] initWithData:imageData scale:6.0];
            if (image == nil) image = [MADCollectionViewCellDocument newDefaultThumbnail];
            dispatch_sync(dispatch_get_main_queue(), ^{
                self.imagePreview.image = image;
            });
        }
    };
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), read_iamge);
   */ 
    if (_editing) [self startWobble];
    else [self stopWobble];

}

- (void)setEditing:(BOOL)editing {
    if (_editing != editing) {
        if ((_editing = editing)) [self startWobble];
        else [self stopWobble];
    }
}

- (NSString *)copySubtitleForStatus:(NSString *)status fileSize:(unsigned long long)fileSize {
    NSString *result;
    result = [status isEqualToString: NSMetadataUbiquitousItemDownloadingStatusNotDownloaded] ?
    NSLocalizedString(MADTextNotDownloaded, MADTextNotDownloaded) :
    [MADStandard newStringForFileSize:fileSize];
    return result;
}

@end
