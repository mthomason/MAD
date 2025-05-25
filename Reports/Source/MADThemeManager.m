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

@end
