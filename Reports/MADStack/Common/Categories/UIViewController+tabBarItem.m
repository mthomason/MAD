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

#import "MADQueryBuilderSplitViewController.h"
#import "MADQueryViewController.h"
#import "MADViewerController.h"
#import "MADDesignerViewController.h"

#import "MADTabBarItemProtocol.h"

@implementation UIViewController (tabBarItem)

+ (void)load {
    static dispatch_once_t onceTokenTabBarItem;
    SEL originalSelectorTabBarItem = @selector(tabBarItem);
    SEL swizzledSelectorTabBarItem = @selector(mad_tabBarItem);
    mad_swizzle_selectors(self, originalSelectorTabBarItem, self, swizzledSelectorTabBarItem, &onceTokenTabBarItem);
}

- (UITabBarItem *)mad_tabBarItem {
    UITabBarItem *tabBarItem = [self mad_tabBarItem];
    if (tabBarItem && tabBarItem.image == nil) {
        UIImage *tabBarImage = [self.class conformsToProtocol:@protocol(MADTabBarImageProtocol)] ?
                                [self.class newTabBarImage] : nil;
        if (tabBarImage) {
            UIImage *tabBarImageOg = [tabBarImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
            tabBarItem.image = tabBarImageOg;
            tabBarItem.selectedImage = tabBarImage;
        }
        NSString *tabBarTitle = self.title.copy;
        tabBarItem.title = tabBarTitle;
    }
    return tabBarItem;
}

+ (UIImage *)newTabBarImage {
    return nil;
}

@end
