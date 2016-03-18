//
//  UITableViewControllerDataSourceTypes.h
//  Reports
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDatabaseDriverSelectorViewController_h
#define Reports_MTDatabaseDriverSelectorViewController_h

#import "MADViewController.h"
#import <MADExplorer/MADSaveFileProtocol.h>
#import "MUIViewControllerDelegate.h"

extern NSString * const MTSegueShowSetUpDatasourceMySqlIdentifier;
extern NSString * const MTSegueShowSetUpDatasourceSqlite3Identifier;
extern NSString * const MTSegueShowSetUpDatasourceSalesForceIdentifier;
extern NSString * const MTSegueShowSetUpDatasourceSqlServerIdentifier;

@interface MTDatabaseDriverSelectorViewController : MADTableViewController
    <MADSaveFileProtocol>

    @property (nonatomic, weak) id <MTViewControllerProtocol> delegate;
    @property (nonatomic, weak) id <MADSaveFileProtocol> saveFileDelegate;

@end

#endif
