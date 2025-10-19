//
//  UIViewController+tabBarItem.m
//  MAD
//
//  Created by Michael Thomason on 3/30/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "UIViewController+tabBarItem.h"

#import <UIKit/UITabBarController.h>
#import <UIKit/UITabBarItem.h>
#import <UIKit/UIImage.h>

#import "objcmad.h"
#import "MADTabBarItemProtocol.h"

@implementation UIViewController (tabBarItem)

+ (void)load {
	static dispatch_once_t onceTokenTabBarItem;
	mad_swizzle_selectors(self, @selector(tabBarItem), self, @selector(mad_tabBarItem), &onceTokenTabBarItem);
}

- (UITabBarItem *)mad_tabBarItem {
	UITabBarItem *tabBarItem = [self mad_tabBarItem];
	if (tabBarItem && tabBarItem.image == nil) {
		if ([self.class conformsToProtocol:@protocol(MADTabBarImageProtocol)]) {
			UIImage *image = [self.class TabBarImage];
			if (image) {
				tabBarItem.image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
				tabBarItem.selectedImage = image;
			}
		}
		tabBarItem.title = self.title;
	}
	return tabBarItem;
}

+ (UIImage *)TabBarImage {
	return nil;
}

@end
