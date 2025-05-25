//
//  MADTraitCollection.m
//  MAD Designer
//
//  Created by Michael on 5/25/25.
//  Copyright © 2025 Everyday Apps LLC. All rights reserved.
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

+ (void)applyAppearanceToNavigationController:(UINavigationController *)navigationController
							  traitCollection:(UITraitCollection *)traitCollection {
	UINavigationBarAppearance *navBarAppearance = [[UINavigationBarAppearance alloc] init];
	UIToolbarAppearance *toolbarAppearance = [[UIToolbarAppearance alloc] init];
	
	UIBarButtonItemAppearance *navBarButtonAppearance = [[UIBarButtonItemAppearance alloc] initWithStyle:UIBarButtonItemStylePlain];
	UIBarButtonItemAppearance *toolbarButtonAppearance = [[UIBarButtonItemAppearance alloc] initWithStyle:UIBarButtonItemStylePlain];
	UIFont *buttonFont = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
	
	if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
		[navBarAppearance configureWithTransparentBackground];
		navBarAppearance.backgroundEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterialDark];
		navBarAppearance.titleTextAttributes = @{
			NSForegroundColorAttributeName: [UIColor whiteColor]
		};
		navBarAppearance.largeTitleTextAttributes = @{
			NSForegroundColorAttributeName: [UIColor whiteColor]
		};
		
		[navBarButtonAppearance.normal setTitleTextAttributes:@{
			NSForegroundColorAttributeName: [UIColor systemBlueColor],
			NSFontAttributeName: buttonFont
		}];
		navBarAppearance.buttonAppearance = navBarButtonAppearance;
		navBarAppearance.doneButtonAppearance = navBarButtonAppearance;
		
		[toolbarAppearance configureWithTransparentBackground];
		toolbarAppearance.backgroundEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterialDark];
		
		[toolbarButtonAppearance.normal setTitleTextAttributes:@{
			NSForegroundColorAttributeName: [UIColor systemBlueColor],
			NSFontAttributeName: buttonFont
		}];
		toolbarAppearance.buttonAppearance = toolbarButtonAppearance;
		toolbarAppearance.doneButtonAppearance = toolbarButtonAppearance;
		
	} else {
		
		[navBarAppearance configureWithOpaqueBackground];
		navBarAppearance.backgroundColor = [MADColorEverydayApps newColorBlue];
		navBarAppearance.titleTextAttributes = @{
			NSForegroundColorAttributeName: [MADColorEverydayApps newColorWhite]
		};
		navBarAppearance.largeTitleTextAttributes = @{
			NSForegroundColorAttributeName: [MADColorEverydayApps newColorWhite]
		};
		
		[navBarButtonAppearance.normal setTitleTextAttributes:@{
			NSForegroundColorAttributeName: [MADColorEverydayApps newColorWhite],
			NSFontAttributeName: buttonFont
		}];
		navBarAppearance.buttonAppearance = navBarButtonAppearance;
		navBarAppearance.doneButtonAppearance = navBarButtonAppearance;
		
		[toolbarAppearance configureWithOpaqueBackground];
		toolbarAppearance.backgroundColor = [UIColor whiteColor];
		
		[toolbarButtonAppearance.normal setTitleTextAttributes:@{
			NSForegroundColorAttributeName: [MADColorEverydayApps newColorBlue],
			NSFontAttributeName: buttonFont
		}];
		
		toolbarAppearance.buttonAppearance = toolbarButtonAppearance;
		toolbarAppearance.doneButtonAppearance = toolbarButtonAppearance;
	}
	
	navigationController.navigationBar.standardAppearance = navBarAppearance;
	navigationController.navigationBar.compactAppearance = navBarAppearance;
	navigationController.navigationBar.scrollEdgeAppearance = navBarAppearance;
	
	navigationController.toolbar.standardAppearance = toolbarAppearance;
	if (@available(iOS 15.0, *)) {
		navigationController.toolbar.scrollEdgeAppearance = toolbarAppearance;
	}
	[navigationController.view setNeedsLayout];
}

+ (void)applyAppearanceToTabBarController:(UITabBarController *)tabBarController
						  traitCollection:(UITraitCollection *)traitCollection {
	UITabBarAppearance *tabBarAppearance = [[UITabBarAppearance alloc] init];
	
	// Create a single UITabBarItemAppearance instance
	UITabBarItemAppearance *itemAppearance = [[UITabBarItemAppearance alloc] init];
	
	if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
		[tabBarAppearance configureWithTransparentBackground];
		tabBarAppearance.backgroundColor = [UIColor clearColor];
		tabBarAppearance.backgroundEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterialDark];
		
		// Configure UNSELECTED state directly on itemAppearance.normal
		[itemAppearance.normal setTitleTextAttributes:@{
			NSForegroundColorAttributeName: [UIColor lightGrayColor]
		}];
		itemAppearance.normal.iconColor = [UIColor lightGrayColor];
		
		// Configure SELECTED state directly on itemAppearance.selected
		[itemAppearance.selected setTitleTextAttributes:@{
			NSForegroundColorAttributeName: [UIColor systemBlueColor]
		}];
		itemAppearance.selected.iconColor = [UIColor systemBlueColor];
		
	} else { // Light mode
		[tabBarAppearance configureWithOpaqueBackground];
		tabBarAppearance.backgroundColor = [MADColorEverydayApps newColorBlue];
		
		// Configure UNSELECTED state directly on itemAppearance.normal
		[itemAppearance.normal setTitleTextAttributes:@{
			NSForegroundColorAttributeName: [[MADColorEverydayApps newColorWhite] colorWithAlphaComponent:0.7]
		}];
		itemAppearance.normal.iconColor = [[MADColorEverydayApps newColorWhite] colorWithAlphaComponent:0.7];
		
		// Configure SELECTED state directly on itemAppearance.selected
		[itemAppearance.selected setTitleTextAttributes:@{
			NSForegroundColorAttributeName: [MADColorEverydayApps newColorWhite]
		}];
		itemAppearance.selected.iconColor = [MADColorEverydayApps newColorWhite];
	}
	
	// Assign the configured itemAppearance (which now includes both normal and selected states)
	// to the relevant layout appearances on the main tabBarAppearance.
	tabBarAppearance.stackedLayoutAppearance = itemAppearance;
	tabBarAppearance.inlineLayoutAppearance = itemAppearance; // If you might use other layouts
	tabBarAppearance.compactInlineLayoutAppearance = itemAppearance; // If you might use other layouts
	
	tabBarController.tabBar.standardAppearance = tabBarAppearance;
	if (@available(iOS 15.0, *)) {
		tabBarController.tabBar.scrollEdgeAppearance = tabBarAppearance;
	}
}

@end
