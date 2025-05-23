//
//  MADQueryViewController.h
//  Reports
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#ifndef Reports_MADQueryViewController_h
#define Reports_MADQueryViewController_h

#import "MADViewControllerDocumentProtocol.h"
#import "MADTabBarItemProtocol.h"
#import "MADQueryNavigationProtocol.h"

#import <UIKit/UITableViewController.h>
#import <UIKit/UIViewControllerTransitioning.h>

extern NSString * const MADImageBarButtonItemDatabase;
extern NSString * const MADImageBarButtonItemDatabase8;

@interface MADQueryViewController : UITableViewController <MADViewControllerDocumentProtocol, MADTabBarImageProtocol, MADQueryNavigationProtocol, UIViewControllerAnimatedTransitioning>

+ (void)deleteCoreDataCache;

- (void)reloadMainDocumentAnimated:(BOOL)animated;
- (IBAction)edit:(id)sender;

@end

#endif
