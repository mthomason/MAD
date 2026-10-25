//
//  MADSearchBar.m
//  MAD
//
//  Created by Michael Thomason on 10/16/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADSearchBar.h"
#import <UIKit/UIImage.h>
#import <UIKit/UIButton.h>
#import <UIKit/UIColor.h>
#import <UIKit/UIImageView.h>

#import "objcmad.h"

@interface MADSearchBar ()

@property (nonatomic, assign, getter=isIconColorUpdated) BOOL updatedIconColor;
@property (nonatomic, assign, getter=isClearButtonUpdated) BOOL updatedClearButtonColor;

@end

@implementation MADSearchBar

+ (void)initialize {
	[super initialize];
	if (self == [MADSearchBar self]) {
		@autoreleasepool {
			MADSearchBar <UIAppearance> *appearanceProxySearchBar;
			UIButton <UIAppearance> *appearanceProxyButton;
			UITextField <UIAppearance> *appearanceProxyTextField;
			UIImageView <UIAppearance> *appearanceProxyImageView;
			NSArray <Class <UIAppearanceContainer>> *classes;
			
			classes = [[NSArray alloc] initWithObjects: [UISearchBar class], nil];
			appearanceProxyButton = [UIButton appearanceWhenContainedInInstancesOfClasses: classes];
			appearanceProxyButton.tintColor = [UIColor whiteColor];
			
			appearanceProxyTextField = [UITextField appearanceWhenContainedInInstancesOfClasses:classes];
			appearanceProxyTextField.tintColor = [UIColor whiteColor];
			appearanceProxyTextField.textColor = [UIColor whiteColor];
			
			appearanceProxyImageView = [UIImageView appearanceWhenContainedInInstancesOfClasses:classes];;
			
			appearanceProxySearchBar = [MADSearchBar appearance];
			UIImage *closeImage = [UIImage imageNamed: @"MADImageClear"];
			UIImage *newImageTemplate = [closeImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
			[appearanceProxySearchBar setImage: newImageTemplate
							  forSearchBarIcon: UISearchBarIconClear
										 state: UIControlStateNormal];
			
		}
	}
}

- (instancetype)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		
		self.updatedIconColor = NO;
		self.updatedClearButtonColor = NO;
		
		
		self.showsBookmarkButton = NO;
		self.showsCancelButton = YES;
		self.showsScopeBar = NO;
		self.showsSearchResultsButton = NO;
		self.hidden = YES;
	}
	return self;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	if (!self.isIconColorUpdated || !self.isClearButtonUpdated) {
		
		UIImage *image;
		UIColor *whiteColor =  [UIColor whiteColor];
		
		UIView *subview;
		NSArray<__kindof UIView *> *subviews;
		NSArray<__kindof UIView *> *subviews2;
		subviews = self.subviews;
		
		for (subview in subviews) {
			
			subviews2 = subview.subviews;
			__kindof UIView * subview2;
			for (subview2 in subviews2) {
				if ([subview2 isKindOfClass:[UITextField class]]) {
					
					image = ((UIImageView *)((UITextField *)subview2).leftView).image;
					UIImage *imageRenderingTemplate = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
					((UIImageView *)((UITextField *)subview2).leftView).image = imageRenderingTemplate;
					((UIImageView *)((UITextField *)subview2).leftView).tintColor = whiteColor.copy;
					imageRenderingTemplate = nil;
					
				}
			}
		}
		self.updatedIconColor = YES;
		self.updatedClearButtonColor  = YES;
		image = nil;
	}
}

@end
