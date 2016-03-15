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

@class MADTabBarController;

@interface MADViewController : UIViewController

#include "MADViewControllerBase.h"

@end

@interface MADTableViewController : UITableViewController

#include "MADViewControllerBase.h"

@end

@interface MADCollectionViewController : UICollectionViewController

#include "MADViewControllerBase.h"

@end

@interface MADSplitViewController : UISplitViewController

#include "MADViewControllerBase.h"

@end

@interface MADPageViewController : UIPageViewController

#include "MADViewControllerBase.h"

@end

#endif
