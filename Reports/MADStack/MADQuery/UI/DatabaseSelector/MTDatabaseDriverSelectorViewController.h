//
//  UITableViewControllerDataSourceTypes.h
//  Reports
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDatabaseDriverSelectorViewController_h
#define Reports_MTDatabaseDriverSelectorViewController_h

#import "MADTableViewController.h"
#import <MADExplorer/MADSaveFileProtocol.h>

extern NSString * const MTSegueShowSetUpDatasourceMySqlIdentifier;
extern NSString * const MTSegueShowSetUpDatasourceSqlite3Identifier;
extern NSString * const MTSegueShowSetUpDatasourceSalesForceIdentifier;
extern NSString * const MTSegueShowSetUpDatasourceSqlServerIdentifier;

@protocol MADViewControllerStandardProtocol;

@interface MTDatabaseDriverSelectorViewController : MADTableViewController
    <MADSaveFileProtocol>

    @property (nonatomic, weak) id <MADViewControllerStandardProtocol> delegate;
    @property (nonatomic, weak) id <MADSaveFileProtocol> saveFileDelegate;

@end

#endif
