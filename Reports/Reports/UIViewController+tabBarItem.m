//
//  UIViewController+tabBarItem.m
//  MAD
//
//  Created by Michael Thomason on 3/30/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "UIViewController+tabBarItem.h"
#import "objcmad.h"

@implementation UIViewController (tabBarItem)

+ (void)load {
    
    Class class = [self class];
    static dispatch_once_t onceTokenTabBarItem;
    SEL originalSelectorTabBarItem = @selector(tabBarItem);
    SEL swizzledSelectorTabBarItem = @selector(mad_tabBarItem);
    mad_swizzle_selectors(class, originalSelectorTabBarItem, class, swizzledSelectorTabBarItem, &onceTokenTabBarItem);
    
}

- (UITabBarItem *)mad_tabBarItem {
    UITabBarItem *tabBarItem = [self mad_tabBarItem];
    if (tabBarItem && [tabBarItem image] == nil) {
        UIImage *tabBarImage = [self tabBarImage];
        if (tabBarImage) {
            UIImage *tabBarImageOg = [tabBarImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
            tabBarItem.image = tabBarImageOg;
            tabBarItem.selectedImage = tabBarImage;
            tabBarItem.title = self.title;
        }
    }
    return tabBarItem;
}

- (UIImage *)tabBarImage {
    return nil;
}

@end
