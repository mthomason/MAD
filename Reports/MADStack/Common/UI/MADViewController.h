//
//  MADViewController.h
//  MAD
//
//  Created by Michael Thomason on 11/13/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADViewController_h
#define MAD_MADViewController_h

#import <UIKit/UIKit.h>


@protocol MTTabBarImageProtocol <NSObject>
@optional
- (UIImage *)tabBarImage;

@end

@class MADTabBarController;

@interface MADViewController : UIViewController
    <MTTabBarImageProtocol>

#include "MADViewControllerBase.h"

@end

@interface MADPageViewController : UIPageViewController
    <MTTabBarImageProtocol>
#include "MADViewControllerBase.h"

@end

@interface MADTableViewController : UITableViewController
    <MTTabBarImageProtocol>
#include "MADViewControllerBase.h"

@end

@interface MADCollectionViewController : UICollectionViewController
    <MTTabBarImageProtocol>
#include "MADViewControllerBase.h"

@end

@interface MADSplitViewController : UISplitViewController
    <MTTabBarImageProtocol>

#include "MADViewControllerBase.h"

@end

#endif
