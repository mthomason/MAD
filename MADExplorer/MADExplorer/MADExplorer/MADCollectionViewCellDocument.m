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
#import "MADExplorerActivityIndicator.h"
#import "MADLabelFileExplorerDocumentCellTitle.h"
#import "MADLabelFileExplorerDocumentCellSubtitle.h"
#import "MADBackgroundViewSelected.h"
#import "MADStandard.h"
#import "MADThumbnailView.h"
#import "MADExplorerCellTitle.h"

#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADFileManager/MADMetaData.h>
#import <MADFoundation/MADURLFactory.h>

#import <UIKit/UINibLoading.h>
#import <UIKit/NSAttributedString.h>
#import <UIKit/UIProgressView.h>
#import <UIKit/UIActivityIndicatorView.h>
#import <UIKit/UIImage.h>
#import <UIKit/UIImageView.h>
#import <UIKit/UILabel.h>
#import <UIKit/UIAccessibility.h>

#import <QuartzCore/CALayer.h>
#import <os/log.h>

#define degreesToRadians(x) (M_PI * (x) / 180.0)
static const CGFloat MTAnimationRotateDeg = 6.0;

static inline double wobbleRandomFactor(void);
static inline double wobbleRandomFactor(void) {
	return (arc4random_uniform(100) / 100.0);
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
		[progressView setProgress:0.0 animated:YES];
		return;
	}
	
	progressView.hidden = NO;
	if (progressView.progress < percent / 100.0) {
		[progressView setProgress: (float) (percent / 100.0) animated: YES];
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
	if (!self.selectedBackgroundView) {
		UIView *selectedBackgroundView = [[MADBackgroundViewSelected alloc] initWithFrame:self.contentView.frame];
		self.selectedBackgroundView = selectedBackgroundView;
	}
	
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
	self.gestureRecognizers = @[];
	self.labelTitle.text = nil;
	self.labelTitleSub.text = nil;
	self.imageCloudIndicator.image = nil;
	[self.progressViewDownload setProgress:0.0f];
	self.progressViewDownload.hidden = YES;
	[self.progressViewUpload setProgress:0.0f];
	self.progressViewUpload.hidden = YES;
	UIActivityIndicatorView *activityIndicator = self.activityIndicator;
	if (activityIndicator) {
		[activityIndicator stopAnimating];
	}
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
	
	NSAttributedString *attributedString = [MADCollectionViewCellDocument explorerCaption:self.labelTitle.text];

	UILabel *labelTitle = _labelTitle;
	labelTitle.attributedText = attributedString;
	labelTitle.text = self.labelTitle.text.copy;

}

+ (NSAttributedString *)explorerCaption:(NSString *)text {
	NSString *caption = [text copy];
	
	NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
	paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
	paragraphStyle.baseWritingDirection = NSWritingDirectionLeftToRight;
	paragraphStyle.alignment = NSTextAlignmentCenter;
	
	UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
	
	NSDictionary<NSAttributedStringKey, id> *attributes = @{
		NSFontAttributeName: font,
		NSParagraphStyleAttributeName: paragraphStyle,
		NSKernAttributeName: [NSNull null]
	};
	
	return [[NSMutableAttributedString alloc] initWithString: caption
												  attributes: attributes];
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
	_wobbling = YES;
	
	// Make sure we are in the view hierarchy
	if (!self.superview) {
		return;
	}
	
	[self.layer removeAllAnimations]; // Clear any previous animations
	self.transform = CGAffineTransformIdentity; // Reset transform before starting a new one
	self.layer.anchorPoint = CGPointMake(0.5, 0.5);
	
	// Randomize aspects of the wobble for a more natural look
	CGFloat randomAngleOffset = (CGFloat)((wobbleRandomFactor() - 0.5) * MTAnimationRotateDeg * 0.5); // Small random offset to base angle
	CGFloat angle = degreesToRadians(MTAnimationRotateDeg + randomAngleOffset);
	NSTimeInterval duration = 0.15 + (wobbleRandomFactor() * 0.1); // Duration between 0.15s and 0.25s
	
	// Start slightly offset so the autoreverse creates a back-and-forth motion around the center
	self.transform = CGAffineTransformMakeRotation(-angle * 0.5f);
	
	typeof(self) __weak weakSelf = self;
	[UIView animateWithDuration:duration
						  delay:0.0
						options:UIViewAnimationOptionAllowUserInteraction |
	 UIViewAnimationOptionRepeat |
	 UIViewAnimationOptionAutoreverse |
	 UIViewAnimationOptionBeginFromCurrentState
					 animations:^{
		typeof(weakSelf) __strong strongSelf = weakSelf;
		if (!strongSelf) return;
		strongSelf.transform = CGAffineTransformMakeRotation(angle);
	} completion:nil];
}

- (void)stopWobble {
	_wobbling = NO;
	if (self.layer.animationKeys.count > 0) {
		[self.layer removeAllAnimations];
	}
	self.transform = CGAffineTransformIdentity;
}

- (void)setWobbling:(BOOL)wobbling {
	if (_wobbling != wobbling) {
		if (wobbling && self.layer.animationKeys.count == 0 && self.superview) {
			[self startWobble];
		}
		return;
	}
	_wobbling = wobbling;
	if (_wobbling) {
		if (self.superview) {
			[self startWobble];
		}
	} else {
		[self stopWobble];
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
	
	self.wobbling = editing;

	UIImageView *cloudIndicatorImageView = self.imageCloudIndicator;
	MADLabelFileExplorerDocumentCellTitle *labelTitle = self.labelTitle;
	MADLabelFileExplorerDocumentCellSubtitle *labelTitleSub = self.labelTitleSub;

	labelTitle.text = [metadata.name copy];

	//NSString *ubiquitousItemDownloadingStatus = metadata.ubiquitousItemDownloadingStatus.copy;
	BOOL notDownloaded = metadata.isUbiquitousItemDownloadingStatusNotDownloaded;
	BOOL isDownloading = metadata.ubiquitousItemIsDownloading;
	BOOL isUploading = metadata.ubiquitousItemIsUploading;
	BOOL isUbiquitous = metadata.isUbiquitous;
	
	labelTitleSub.text = [MADExplorerCellTitle explorerCellTitleSubtitle:metadata];
	
	[self setUploadingActive: isUploading percent: metadata.ubiquitousItemPercentUploaded];
	[self setDownloadingActive:isDownloading percent: metadata.ubiquitousItemPercentDownloaded];
	
	UIImage *cloudIndicatorImage = notDownloaded && isUbiquitous ?
								[UIImage imageNamed:@"MADImageToolbarCloudDownload"] : nil;
	[cloudIndicatorImageView setImage: cloudIndicatorImage];
	
	[labelTitle setNeedsLayout];
	[labelTitleSub setNeedsLayout];
	[labelTitle setNeedsDisplay];
	[labelTitleSub setNeedsDisplay];
	
	dispatch_block_t read_iamge = ^{
		@autoreleasepool {
			NSURL *metadataURL = [metadata.URL copy];
			NSURL *thumbnailUrl = [MADURLFactory newURLThumbnailForURL:metadataURL];
			[[NSOperationQueue mainQueue] addOperationWithBlock:^{
				UIActivityIndicatorView *activityIndicatorView = self.activityIndicator;
				if (isDownloading || isUploading) {
					[activityIndicatorView performSelector:@selector(startAnimating)];
				} else {
					[activityIndicatorView performSelector:@selector(stopAnimating)];
				}
				if ([self.labelTitle.text isEqualToString:metadata.name]) {
					self.imagePreview.thumbnailURL = thumbnailUrl;
				}
			}];
		}
	};
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), read_iamge);

}

@end
