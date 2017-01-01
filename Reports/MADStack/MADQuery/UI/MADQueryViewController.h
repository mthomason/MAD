//
//  MADQueryViewController.h
//  Reports
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADQueryViewController_h
#define Reports_MADQueryViewController_h

#import <UIKit/UITableViewController.h>
#import "MADViewControllerDocumentProtocol.h"

extern NSString * const MADImageBarButtonItemDatabase;
extern NSString * const MADImageBarButtonItemDatabase8;
extern NSString * const MADSegueShowSql;

//@protocol MADViewControllerStandardProtocol;

@interface MADQueryViewController : UITableViewController
    <MADViewControllerDocumentProtocol>

    + (void)deleteCoreDataCache;

    - (void)reloadMainDocumentAnimated:(BOOL)animated;
    - (IBAction)edit:(id)sender;

@end

#endif
