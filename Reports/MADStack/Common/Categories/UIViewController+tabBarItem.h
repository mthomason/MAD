//
//  UIViewController+tabBarItem.h
//  MAD
//
//  Created by Michael Thomason on 3/30/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_UIViewController_tabBarItem_h
#define Reports_UIViewController_tabBarItem_h

#import <UIKit/UIKit.h>

@protocol MTTabBarImageProtocol <NSObject>

- (UIImage *)tabBarImage;

@end

@interface UIViewController (tabBarItem) <MTTabBarImageProtocol>

@end

#endif
