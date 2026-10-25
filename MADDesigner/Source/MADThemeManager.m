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
					   traitCollection:(UITraitCollection *)traitCollection {
	if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
		barButtonItem.tintColor = [MADColorEverydayApps newColorWhite];
	} else {
		barButtonItem.tintColor = [MADColorEverydayApps newColorWhite];
	}
}

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
		[navBarButtonAppearance.disabled setTitleTextAttributes:@{
			NSForegroundColorAttributeName: [UIColor systemPinkColor],
			NSFontAttributeName: buttonFont
		}];

		navBarAppearance.buttonAppearance = navBarButtonAppearance;
		navBarAppearance.doneButtonAppearance = navBarButtonAppearance;
		
		[toolbarAppearance configureWithOpaqueBackground];
		toolbarAppearance.backgroundColor = [MADColorEverydayApps newColorBlue]; // Match navigation bar color
		
		[toolbarButtonAppearance.normal setTitleTextAttributes:@{
			NSForegroundColorAttributeName: [MADColorEverydayApps newColorWhite], // Make buttons white
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
	UITabBarItemAppearance *itemAppearance = [[UITabBarItemAppearance alloc] init];
	
	if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
		[tabBarAppearance configureWithTransparentBackground];
		tabBarAppearance.backgroundColor = [UIColor clearColor];
		tabBarAppearance.backgroundEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterialDark];
	} else {
		[tabBarAppearance configureWithOpaqueBackground];
		tabBarAppearance.backgroundColor = [MADColorEverydayApps newColorBlue];
	}
	
	NSDictionary *whiteTextAttributes = @{
		NSForegroundColorAttributeName: [MADColorEverydayApps newColorWhite],
		NSFontAttributeName: [UIFont systemFontOfSize:10 weight:UIFontWeightMedium]
	};
	
	[itemAppearance.normal setTitleTextAttributes:whiteTextAttributes];
	itemAppearance.normal.iconColor = [MADColorEverydayApps newColorWhite];
	
	[itemAppearance.selected setTitleTextAttributes:whiteTextAttributes];
	itemAppearance.selected.iconColor = [MADColorEverydayApps newColorRed];

	tabBarAppearance.stackedLayoutAppearance = itemAppearance;
	tabBarAppearance.inlineLayoutAppearance = itemAppearance;
	tabBarAppearance.compactInlineLayoutAppearance = itemAppearance;
	
	tabBarController.tabBar.standardAppearance = tabBarAppearance;
	if (@available(iOS 15.0, *)) {
		tabBarController.tabBar.scrollEdgeAppearance = tabBarAppearance;
	}
}

@end
