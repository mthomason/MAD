//
//  MADQueryViewController.h
//  Reports
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADQueryViewController_h
#define Reports_MADQueryViewController_h

#import <UIKit/UITableViewController.h>
#import <UIKit/UIViewControllerTransitioning.h>
#import "MADViewControllerDocumentProtocol.h"
#import "MADTabBarItemProtocol.h"
#import "MADQueryNavigationProtocol.h"

extern NSString * const MADImageBarButtonItemDatabase;
extern NSString * const MADImageBarButtonItemDatabase8;
extern NSString * const MADSegueShowSql;

@interface MADQueryViewController : UITableViewController
    <MADViewControllerDocumentProtocol,
        MADTabBarImageProtocol,
        MADQueryNavigationProtocol,
        UIViewControllerAnimatedTransitioning>

    + (instancetype)newQueryViewController:(MADocument *)document;

    + (void)deleteCoreDataCache;

    - (void)reloadMainDocumentAnimated:(BOOL)animated;
    - (IBAction)edit:(id)sender;

@end

#endif
