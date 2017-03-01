//
//  MADCollectionViewCellDocument.m
//  Reports
//
//  Created by Michael Thomason on 2/19/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADCollectionViewCellDocument.h"

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
#import <MADFileManager/MADMetaData.h>
#import <MADFoundation/MADURL.h>

#import "MADExplorerCaption.h"
#import "MADExplorerActivityIndicator.h"

#import "MADLabelFileExplorerDocumentCellTitle.h"
#import "MADLabelFileExplorerDocumentCellSubtitle.h"

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

static const CGFloat Float_0                    =   0.00000000f;
static const CGFloat Float_100                  = 100.00000000f;

static inline float wobbleFactor(void);
static inline BOOL isStatusNotDownloading(NSString *);

static inline float wobbleFactor() {
    return (arc4random_uniform(500) / 500.0000f) + 0.5000f;
}

static inline BOOL isStatusNotDownloading(NSString *status) {
    BOOL result = [status isEqualToString: NSMetadataUbiquitousItemDownloadingStatusNotDownloaded];
    return result;
}

@interface MADCollectionViewCellDocument ()
    @property (nonatomic, readwrite, weak) UIActivityIndicatorView *activityIndicator;
@end

@implementation MADStringFormatted

+ (NSString *)newStringFormattedSubtitle:(NSString *)status
                                fileSize:(unsigned long long)fileSize {
    id result;
    if (isStatusNotDownloading(status)) {
        NSString *textNotDownloaded = NSLocalizedString(MADTextNotDownloaded, MADTextNotDownloaded);
        result = [[NSString alloc] initWithString:textNotDownloaded];
    } else {
        result = [MADStandard newStandardStringForFileSize:fileSize];
    }
    return result;
}

@end

@implementation MADCollectionViewCellDocument {
    bool _wobbling;
  @protected
    UIView * _selectedBackgroundView;
}

#pragma mark -
#pragma mark Overrides

- (void)setSelected:(BOOL)selected {
    NSLog(@"%s %s", __PRETTY_FUNCTION__, selected ? "YES" : "NO");
    [super setSelected:selected];
    [_labelTitle setSelected:selected];
}

- (void)setHighlighted:(BOOL)highlighted {
    NSLog(@"%s %s", __PRETTY_FUNCTION__, highlighted ? "YES" : "NO");
    [super setHighlighted: highlighted];
    [_labelTitle setHighlighted: highlighted];
}

#pragma mark -
#pragma mark NSObject

- (void)dealloc {
    [self setSelectedBackgroundView:nil];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    _wobbling = false;
    UIView *selectedBackgroundView = [[MADBackgroundViewSelected alloc]
                                      initWithFrame:self.contentView.frame];
    [self setSelectedBackgroundView: selectedBackgroundView];
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

#pragma mark -
#pragma mark UIView

- (void)setNeedsLayout {
    [super setNeedsLayout];
    [_labelTitle setNeedsLayout];
    [_labelTitleSub setNeedsLayout];
}

- (void)setBounds:(CGRect)bounds {
    super.bounds = bounds;
    self.contentView.frame = bounds;
}

#pragma mark -
#pragma mark UICollectionReusableView

- (void)prepareForReuse {
    [super prepareForReuse];
    [self stopWobble];
    [self.imagePreview prepareForReuse];
    NSArray *gestureRecognizers = [[NSArray alloc] init];
    self.gestureRecognizers = gestureRecognizers;
}

#pragma mark -
#pragma mark Lazy Load

- (UIActivityIndicatorView *)activityIndicator {
    UIActivityIndicatorView *result = _activityIndicator;
    if (result == nil) {
        result = [MADExplorerActivityIndicator newExplorerActivityIndicator];
        result.center = self.contentView.center;
        [self.contentView addSubview:result];
        _activityIndicator = result;
    }
    return result;
}

#pragma mark -
#pragma mark Helpers

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

- (void)setText:(NSString *)text {
    id attributedString;
    attributedString = [MADExplorerCaption newExplorerCaption:text];
    UILabel *labelTitle = _labelTitle;
    labelTitle.attributedText = attributedString;
    labelTitle.text = text.copy;
    attributedString = nil;
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

- (NSString *)titleLabelText {
    return _labelTitle.text;
}

- (UIAccessibilityTraits)accessibilityTraits {
    return UIAccessibilityTraitButton;
}

+ (void)updateProgressView:(UIProgressView *)progressView
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

- (void)setUploadingActive:(BOOL)active
                   percent:(double)percent {
    UIProgressView *progressView = _progressViewUpload;
    [[self class] updateProgressView: progressView
                              active: active
                             percent: percent];
}

- (void)setDownloadingActive:(BOOL)active
                     percent:(double)percent {
    UIProgressView *progressView = _progressViewDownload;
    [[self class] updateProgressView: progressView
                              active: active
                             percent: percent];
    
}

- (void)updateDisplayForMetaData:(MADMetaData *)metadata editing:(BOOL)editing {
    
    BOOL notDownloaded, isDownloading, isUploading, isUbiquitous;
    double percentage;
    
    MADLabelFileExplorerDocumentCellTitle *labelTitle;
    MADLabelFileExplorerDocumentCellSubtitle *labelTitleSub;
    
    UIActivityIndicatorView *activityIndicator;
    UIImageView *cloudIndicatorImageView;
    MADThumbnailView *imagePreview;
    UIImage *cloudIndicatorImage;

    self.wobbling = editing;
    NSString *name, *subtitle, *ubiquitousItemDownloadingStatus;
    
    cloudIndicatorImageView = self.imageCloudIndicator;
    
    labelTitle = self.labelTitle;
    labelTitleSub = self.labelTitleSub;
    
    name = metadata.name;
    labelTitle.text = name.copy;
    
    
    ubiquitousItemDownloadingStatus = metadata.ubiquitousItemDownloadingStatus.copy;
    notDownloaded = isStatusNotDownloading(ubiquitousItemDownloadingStatus);
    isDownloading = metadata.ubiquitousItemIsDownloading;
    isUploading = metadata.ubiquitousItemIsUploading;
    isUbiquitous = metadata.isUbiquitous;
    
    if (isDownloading) {

        subtitle = NSLocalizedString(Downloading, Downloading);
    
    } else if (isUploading) {
    
        subtitle = NSLocalizedString(Syncing, Syncing);
    
    } else {
        
        unsigned long long fileSize = metadata.fileSystemFileSize;
        subtitle = [MADStringFormatted newStringFormattedSubtitle: ubiquitousItemDownloadingStatus
                                                         fileSize: fileSize];
        
    }
    
    labelTitleSub.text = subtitle.copy;
    
    percentage = metadata.ubiquitousItemPercentUploaded;
    [self setUploadingActive: isUploading percent: percentage];
    
    percentage = metadata.ubiquitousItemPercentDownloaded;
    [self setDownloadingActive:isDownloading percent: percentage];
    
    cloudIndicatorImage = notDownloaded && isUbiquitous ?
                                [UIImage imageNamed:@"MADImageToolbarCloudDownload"] : nil;
    
    [cloudIndicatorImageView setImage: cloudIndicatorImage];
    
    [labelTitle setNeedsLayout];
    [labelTitleSub setNeedsLayout];
    [labelTitle setNeedsDisplay];
    [labelTitleSub setNeedsDisplay];
    
    activityIndicator = self.activityIndicator;
    SEL animateSwitch = isDownloading || isUploading ? @selector(startAnimating) :
                                                       @selector(stopAnimating);
    dispatch_block_t read_iamge = ^{
        @autoreleasepool {
            NSURL *metadataURL, *thumbnailUrl;
            [self.activityIndicator performSelectorOnMainThread: animateSwitch
                                                     withObject: nil
                                                  waitUntilDone: NO];

            metadataURL = metadata.URL.copy;
            thumbnailUrl = [MADURL newURLThumbnailForURL:metadataURL];
            imagePreview.thumbnailURL = thumbnailUrl;
            
        }
    };
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), read_iamge);

}

- (void)setWobbling:(BOOL)wobbling {
    if (_wobbling != wobbling) {
        if ((_wobbling = wobbling)) [self startWobble];
        else [self stopWobble];
    }
}

- (NSString *)subtitleForStatus:(NSString *)status
                       fileSize:(unsigned long long)fileSize {
    id result;
    if (isStatusNotDownloading(status)) {
        NSString *textNotDownloaded = NSLocalizedString(MADTextNotDownloaded, MADTextNotDownloaded);
        result = [[NSString alloc] initWithString:textNotDownloaded];
    } else {
        result = [MADStandard newStandardStringForFileSize:fileSize];
    }
    return result;
}

@end
