//
//  MADTraitCollection.m
//  MAD Designer
//
//  Created by Michael on 5/25/25.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADThemeManager.h"

#import <MADCocoaExtensions/UIColor+EverydayApps.h>

#import <UIKit/UINavigationBarAppearance.h>
#import <UIKit/UIToolbarAppearance.h>
#import <UIKit/UIBlurEffect.h>
#import <UIKit/NSAttributedString.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UIToolbar.h>
#import <UIKit/UITabBarController.h>
#import <UIKit/UITabBarAppearance.h>
#import <UIKit/UIBarAppearance.h>

@implementation MADThemeManager

+ (CGFloat)borderWidthThin { return 1.0; }

+ (void)applyAppearanceToBarButtonItem:(UIBarButtonItem *)barButtonItem
					   traitCollection:(UITraitCollection * __unused)traitCollection {
	barButtonItem.tintColor = nil;
}

+ (void)applyAppearanceToNavigationController:(UINavigationController *)navigationController
							  traitCollection:(UITraitCollection * __unused)traitCollection {
	UINavigationBarAppearance *navBarAppearance = [[UINavigationBarAppearance alloc] init];
	UIToolbarAppearance *toolbarAppearance = [[UIToolbarAppearance alloc] init];
	
	UIBarButtonItemAppearance *navBarButtonAppearance = [[UIBarButtonItemAppearance alloc] initWithStyle:UIBarButtonItemStylePlain];
	UIBarButtonItemAppearance *toolbarButtonAppearance = [[UIBarButtonItemAppearance alloc] initWithStyle:UIBarButtonItemStylePlain];
	UIFont *buttonFont = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
	NSDictionary *normalAttributes = @{
		NSForegroundColorAttributeName: [UIColor systemBlueColor],
		NSFontAttributeName: buttonFont
	};
	NSDictionary *disabledAttributes = @{
		NSForegroundColorAttributeName: [UIColor tertiaryLabelColor],
		NSFontAttributeName: buttonFont
	};
	
	[navBarAppearance configureWithDefaultBackground];
	navBarAppearance.titleTextAttributes = @{
		NSForegroundColorAttributeName: [UIColor labelColor]
	};
	navBarAppearance.largeTitleTextAttributes = @{
		NSForegroundColorAttributeName: [UIColor labelColor]
	};
	[navBarButtonAppearance.normal setTitleTextAttributes:normalAttributes];
	[navBarButtonAppearance.disabled setTitleTextAttributes:disabledAttributes];
	navBarAppearance.buttonAppearance = navBarButtonAppearance;
	navBarAppearance.doneButtonAppearance = navBarButtonAppearance;
	
	[toolbarAppearance configureWithDefaultBackground];
	[toolbarButtonAppearance.normal setTitleTextAttributes:normalAttributes];
	[toolbarButtonAppearance.disabled setTitleTextAttributes:disabledAttributes];
	toolbarAppearance.buttonAppearance = toolbarButtonAppearance;
	toolbarAppearance.doneButtonAppearance = toolbarButtonAppearance;
	
	navigationController.navigationBar.tintColor = [UIColor systemBlueColor];
	navigationController.navigationBar.standardAppearance = navBarAppearance;
	navigationController.navigationBar.compactAppearance = navBarAppearance;
	navigationController.navigationBar.scrollEdgeAppearance = navBarAppearance;
	navigationController.navigationBar.compactScrollEdgeAppearance = navBarAppearance;
	
	navigationController.toolbar.tintColor = [UIColor systemBlueColor];
	navigationController.toolbar.standardAppearance = toolbarAppearance;
	navigationController.toolbar.compactAppearance = toolbarAppearance;
	navigationController.toolbar.scrollEdgeAppearance = toolbarAppearance;
	navigationController.toolbar.compactScrollEdgeAppearance = toolbarAppearance;
	[navigationController.view setNeedsLayout];
}

+ (void)applyAppearanceToTabBarController:(UITabBarController *)tabBarController
						  traitCollection:(UITraitCollection * __unused)traitCollection {
	UITabBarAppearance *tabBarAppearance = [[UITabBarAppearance alloc] init];
	UITabBarItemAppearance *itemAppearance = [[UITabBarItemAppearance alloc] init];
	
	[tabBarAppearance configureWithDefaultBackground];
	
	UIFont *tabFont = [UIFont systemFontOfSize:10 weight:UIFontWeightMedium];
	NSDictionary *normalTextAttributes = @{
		NSForegroundColorAttributeName: [UIColor labelColor],
		NSFontAttributeName: tabFont
	};
	NSDictionary *selectedTextAttributes = @{
		NSForegroundColorAttributeName: [UIColor systemBlueColor],
		NSFontAttributeName: tabFont
	};
	
	[itemAppearance.normal setTitleTextAttributes:normalTextAttributes];
	itemAppearance.normal.iconColor = [UIColor labelColor];
	
	[itemAppearance.selected setTitleTextAttributes:selectedTextAttributes];
	itemAppearance.selected.iconColor = [UIColor systemBlueColor];

	tabBarAppearance.stackedLayoutAppearance = itemAppearance;
	tabBarAppearance.inlineLayoutAppearance = itemAppearance;
	tabBarAppearance.compactInlineLayoutAppearance = itemAppearance;
	
	tabBarController.tabBar.tintColor = [UIColor systemBlueColor];
	tabBarController.tabBar.unselectedItemTintColor = [UIColor labelColor];
	tabBarController.tabBar.standardAppearance = tabBarAppearance;
	tabBarController.tabBar.scrollEdgeAppearance = tabBarAppearance;
	[tabBarController.tabBar setNeedsLayout];
	[tabBarController.view setNeedsLayout];
}

@end
