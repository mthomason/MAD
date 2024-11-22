//
//  MADCollectionViewCellDocument.m
//  Reports
//
//  Created by Michael Thomason on 2/19/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
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
#import "MADExplorerCellTitle.h"

#define degreesToRadians(x) (M_PI * (x) / 180.0)
const CGFloat MTAnimationRotateDeg = 1.0000f;
#define degreesToRadians(x) (M_PI * (x) / 180.0)
#define kAnimationRotateDeg 1.0

static const CGFloat Float_0                    =   0.0;
static const CGFloat Float_100                  = 100.0;

static inline double wobbleFactor(void);
static inline double wobbleFactor() {
	return (arc4random_uniform(500) / 500.0) + 0.5;
}

@interface MADCollectionViewCellDocument ()
	@property (nonatomic, readwrite, weak) UIActivityIndicatorView *activityIndicator;
@end

@implementation MADCollectionViewCellDocument {
  @protected
	UIView * _selectedBackgroundView;
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
		[progressView setProgress: (float) (percent / Float_100) animated: YES];
	}
}

#pragma mark -
#pragma mark NSObject

- (void)dealloc {
	[self.layer removeAllAnimations];
	[self setSelectedBackgroundView:nil];
}

- (void)awakeFromNib {
	[super awakeFromNib];
	_wobbling = NO;
	UIView *selectedBackgroundView = [[MADBackgroundViewSelected alloc]
									  initWithFrame:self.contentView.frame];
	[self setSelectedBackgroundView: selectedBackgroundView];
	self.translatesAutoresizingMaskIntoConstraints = NO;
	self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
}

#pragma mark -
#pragma mark Overrides

- (void)removeFromSuperview {
	_wobbling = NO;
	_working = NO;
	[super removeFromSuperview];
}

- (void)setHidden:(BOOL)hidden {
	[super setHidden:hidden];
}

- (void)setSelected:(BOOL)selected {
	[super setSelected:selected];
	[_labelTitle setSelected:selected];
}

- (void)setHighlighted:(BOOL)highlighted {
	[super setHighlighted: highlighted];
	[_labelTitle setHighlighted: highlighted];
}

- (void)setWorking:(BOOL)working {
	UIActivityIndicatorView *activityIndicator = self.activityIndicator;
	if (working) {
		[activityIndicator startAnimating];
	} else {
		[activityIndicator stopAnimating];
	}
	_working = working;
}

#pragma mark -
#pragma mark Accessibility

- (NSString *)accessibilityHintDocumentName {
	NSString *documentName = NSLocalizedString(@"Document %@.",
											   @"Document %@.");
	NSString *label = [[NSString alloc] initWithFormat: documentName, _labelTitle.text];
	return label;
}

- (NSString *)accessibilityHintActionSelect {
	NSString *format = _wobbling ? NSLocalizedString(@"Selects document named %@.",
													 @"Selects document named %@.") :
								   NSLocalizedString(@"Opens document named %@.",
													 @"Opens document named %@.");
	NSString *result = [[NSString alloc] initWithFormat: format, self.labelTitle.text];
	return result;
}

#pragma mark -
#pragma mark Overrides

- (BOOL)shouldGroupAccessibilityChildren {
	return YES;
}

- (BOOL)isAccessibilityElement {
	return NO;
}

- (NSString *)accessibilityHint {
	return [self accessibilityHintActionSelect];
}

- (NSString *)accessibilityLabel {
	return [self accessibilityHintDocumentName];
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
			UIImageView *imagePreview = _imagePreview;
			imagePreview.isAccessibilityElement = YES;
			NSString *text;
			
			text = [self accessibilityHintActionSelect];
			imagePreview.accessibilityHint = text.copy;
			
			text = [self accessibilityHintDocumentName];
			imagePreview.accessibilityLabel = text.copy;
			
			imagePreview.accessibilityTraits = UIAccessibilityTraitButton;
			return imagePreview;
			break;
		}
		case 1: {
			UILabel *labelTitle = _labelTitle;
			NSString *text;
			labelTitle.isAccessibilityElement = YES;
			text = [self accessibilityHintDocumentName];
			labelTitle.accessibilityLabel = text.copy;
			labelTitle.accessibilityHint = NSLocalizedString(@"Renames document.",
															 @"Renames document.");
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

#pragma mark -
#pragma mark UIView

- (void)setNeedsLayout {
	[super setNeedsLayout];
	[_labelTitle setNeedsLayout];
	[_labelTitleSub setNeedsLayout];
}

- (void)setBounds:(CGRect)bounds {
	[super setBounds: bounds];
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


- (void)handleContentSizeCategoryDidChangeNotification {
	
	NSAttributedString *attributedString;
	attributedString = [MADExplorerCaption newExplorerCaption:self.labelTitle.text];

	UILabel *labelTitle = _labelTitle;
	labelTitle.attributedText = attributedString;
	labelTitle.text = self.labelTitle.text.copy;

}

#pragma mark Motion Effects

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

#pragma mark Wobble

- (void)startWobble {

	_wobbling = YES;
	double r = wobbleFactor();
	[self.layer removeAllAnimations];
	self.transform = CGAffineTransformIdentity;
	self.layer.anchorPoint = CGPointMake(0.5, 0.5);

	typeof(self) __weak weakself = self;
	[UIView animateWithDuration: 0.2 animations: ^{
		weakself.transform = CGAffineTransformMakeRotation((CGFloat)degreesToRadians((kAnimationRotateDeg * -1.0) - r));
	} completion: ^(BOOL finishedInital) {
						 
		[UIView animateWithDuration: 0.2
							  delay: 0.0
							options: UIViewAnimationOptionAllowUserInteraction |
										UIViewAnimationOptionRepeat |
										UIViewAnimationOptionAutoreverse |
										UIViewAnimationOptionBeginFromCurrentState
						 animations: ^(void){
							 [UIView setAnimationRepeatCount: MAXFLOAT];
							 weakself.transform = CGAffineTransformMakeRotation((CGFloat)degreesToRadians(kAnimationRotateDeg + r ));
						 } completion:^(BOOL finished) {
							 typeof(self) strongself = weakself;
							 if (!finished && strongself.wobbling && strongself.superview != nil) {
								 [strongself startWobble];
							 }
						 }];
	}];
}

- (void)stopWobble {
	_wobbling = NO;
	[self.layer removeAllAnimations];
	self.transform = CGAffineTransformIdentity;
}

- (void)setWobbling:(BOOL)wobbling {
	if (_wobbling != wobbling) {
		if ((_wobbling = wobbling)) [self startWobble];
		else [self stopWobble];
	}
}

- (void)setTransform:(CGAffineTransform)transform {
	[super setTransform:transform];
}

#pragma mark Progress

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

#pragma mark Update Display

- (void)updateDisplayForMetaData:(MADMetaData *)metadata editing:(BOOL)editing {
	
	BOOL notDownloaded, isDownloading, isUploading, isUbiquitous;
	double percentage;
	
	MADLabelFileExplorerDocumentCellTitle *labelTitle;
	MADLabelFileExplorerDocumentCellSubtitle *labelTitleSub;
	
	UIImageView *cloudIndicatorImageView;
	UIImage *cloudIndicatorImage;

	self.wobbling = editing;
	NSString *name, *subtitle, *ubiquitousItemDownloadingStatus;
	
	cloudIndicatorImageView = self.imageCloudIndicator;
	
	labelTitle = self.labelTitle;
	labelTitleSub = self.labelTitleSub;

	name = metadata.name;
	labelTitle.text = name.copy;

	ubiquitousItemDownloadingStatus = metadata.ubiquitousItemDownloadingStatus.copy;
	notDownloaded = metadata.isUbiquitousItemDownloadingStatusNotDownloaded;
	isDownloading = metadata.ubiquitousItemIsDownloading;
	isUploading = metadata.ubiquitousItemIsUploading;
	isUbiquitous = metadata.isUbiquitous;
	
	subtitle = [MADExplorerCellTitle newExplorerCellTitleSubtitle:metadata];
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
	
	dispatch_block_t read_iamge = ^{
		@autoreleasepool {
			[[NSOperationQueue mainQueue] addOperationWithBlock:^{
				NSURL *metadataURL, *thumbnailUrl;
				UIActivityIndicatorView *activityIndicatorView = self.activityIndicator;
				if (isDownloading || isUploading) {
					[activityIndicatorView performSelector:@selector(startAnimating)];
				} else {
					[activityIndicatorView performSelector:@selector(stopAnimating)];
				}
				metadataURL = metadata.URL.copy;
				thumbnailUrl = [MADURL newURLThumbnailForURL:metadataURL];
				self.imagePreview.thumbnailURL = thumbnailUrl;
			}];
			
		}
	};
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), read_iamge);

}

@end
