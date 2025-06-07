//
//  MADExplorerSectionHeaderView.m
//  MAD
//
//  Created by Michael Thomason on 10/8/14.
//  Copyright © 2020 Michael Thomason. All rights reserved.
//

#import "MADExplorerSectionHeaderView.h"

#import <UIKit/UIActivityIndicatorView.h>
#import <UIKit/UINibLoading.h>
#import <UIKit/UILabel.h>
#import <UIKit/NSAttributedString.h>

#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADCocoaExtensions/MADViewHelpers.h>

NSString * const MADTextCloud = @"Cloud";
NSString * const MADTextLocal = @"Local";

NSString * const MADIdentifierOpenFileSectionHeader = @"MADIdentifierOpenFileSectionHeader";

static inline CGRect MADFrameActivityView(CGSize, CGSize);

static inline CGRect MADFrameActivityView(CGSize view, CGSize activityView) {
	return CGRectMake(view.width - activityView.width - 10.0,
					  ((view.height - activityView.height) / 2.0),
					  activityView.width,
					  activityView.height);;
}


@interface MADExplorerSectionHeaderView ()

	@property (nonatomic, strong) UILabel *label;

	@property (nonatomic, strong) NSString *localizedTextCloud;
	@property (nonatomic, strong) NSString *localizedTextLocal;
	@property (nonatomic, strong) NSAttributedString *localizedAttrbiutedTextCloud;
	@property (nonatomic, strong) NSAttributedString *localizedAttrbiutedTextLocal;

	@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;

	@property (nonatomic, strong) NSString *fontType;

@end

@implementation MADExplorerSectionHeaderView

/*
+ (void)initialize {
	[super initialize];
	if (self == [MADExplorerSectionHeaderView self]) {
		@autoreleasepool {
			UIActivityIndicatorView <UIAppearance> *appearanceProxy;
			NSArray <Class <UIAppearanceContainer>> *classes;
			classes = [[NSArray alloc] initWithObjects: self, nil];
			appearanceProxy = [UIActivityIndicatorView appearanceWhenContainedInInstancesOfClasses:classes];
			appearanceProxy.tintColor = [UIColor whiteColor];
			appearanceProxy.color     = [UIColor whiteColor];
		}
	}
}
*/

- (void)awakeFromNib {
	[super awakeFromNib];
}

- (UICollectionViewLayoutAttributes *)preferredLayoutAttributesFittingAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {
	return [super preferredLayoutAttributesFittingAttributes:layoutAttributes];
}

- (instancetype)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		
		self.localizedTextCloud = NSLocalizedString(MADTextCloud, MADTextCloud);
		self.localizedTextLocal = NSLocalizedString(MADTextLocal, MADTextLocal);
		self.fontType = UIFontTextStyleHeadline;
		self.sectionType = MACloudManagerSectionLocal;

		UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(CGPointZero.x + 10.0, CGPointZero.y, frame.size.width - 10.0, frame.size.height)];
		label.textAlignment = NSTextAlignmentLeft;
		label.font = [UIFont preferredFontForTextStyle:self.fontType];
		label.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
		label.text = NSLocalizedString(MADTextLocal, MADTextLocal);
		[self addSubview: label];

		UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
		activityView.hidesWhenStopped = YES;
		activityView.frame = MADFrameActivityView(self.frame.size, activityView.frame.size);
		[activityView stopAnimating];
		activityView.tintColor = [UIColor whiteColor];
		activityView.color = [UIColor whiteColor];
		[self addSubview: activityView];

		self.activityIndicatorView = activityView;
		
		NSAttributedString *attributedStringLocal = [[NSAttributedString alloc] initWithString: NSLocalizedString(MADTextLocal, MADTextLocal)
																					attributes: @{ NSForegroundColorAttributeName: [MADColorEverydayApps newColorRed] }];
		self.localizedAttrbiutedTextLocal = attributedStringLocal;
		
		NSAttributedString *attributedStringCloud = [[NSAttributedString alloc] initWithString: NSLocalizedString(MADTextCloud, MADTextCloud)
																					attributes: @{ NSForegroundColorAttributeName: [MADColorEverydayApps newColorRed] }];
		self.localizedAttrbiutedTextCloud = attributedStringCloud;
		
		self.backgroundColor = [MADColorEverydayApps newColorHeaderColor];
		label.backgroundColor = [UIColor clearColor];
		label.textColor = [MADColorEverydayApps newColorRed];
		
		self.label = label;
	}
	return self;
}

- (void)startAnimating {
	[self.activityIndicatorView startAnimating];
}

- (void)stopAnimating {
	[self.activityIndicatorView stopAnimating];
}

- (void)setSectionType:(MACloudManagerSection)sectionType {
	if (_sectionType != sectionType) {
		_sectionType = sectionType;
		[self setNeedsDisplay];
	}
}

- (void)setNeedsDisplay {
	[super setNeedsDisplay];
	if (_label != nil) {
		_label.font = [UIFont preferredFontForTextStyle:self.fontType];
		switch (self.sectionType) {
				
			case MACloudManagerSectionCloud:
				_label.attributedText = [_localizedAttrbiutedTextCloud copy];
				break;
				
			case MACloudManagerSectionLocal:
				_label.attributedText = [_localizedAttrbiutedTextLocal copy];
				break;
								
			default:
				_label.attributedText = nil;
				_label.text = @"";
				break;
		}
	}
	[_label sizeToFit];
	
	_label.frame = CGRectMake(CGPointZero.x + 10.0, CGPointZero.y, _label.frame.size.width + 5.0, self.frame.size.height);
	_activityIndicatorView.frame = CGRectMake(_label.frame.origin.x + _label.frame.size.width + 5.0,
											  _activityIndicatorView.frame.origin.y,
											  _activityIndicatorView.frame.size.width,
											  _activityIndicatorView.frame.size.height);
}

@end
