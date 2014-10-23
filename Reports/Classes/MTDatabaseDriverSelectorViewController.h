//
//  UITableViewControllerDataSourceTypes.h
//  Reports
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDatabaseDriverSelectorViewController_h
#define Reports_MTDatabaseDriverSelectorViewController_h

extern NSString * const MTSegueShowSetUpDatasourceMySqlIdentifier;
extern NSString * const MTSegueShowSetUpDatasourceSqlite3Identifier;
extern NSString * const MTSegueShowSetUpDatasourceSalesForceIdentifier;
extern NSString * const MTSegueShowSetUpDatasourceSqlServerIdentifier;

#import <UIKit/UIKit.h>
#import "MUIViewControllerDelegate.h"

@interface MTDatabaseDriverSelectorViewController : UITableViewController

@property (nonatomic, weak) IBOutlet id <MTViewControllerProtocol> delegate;

@end

#endif
