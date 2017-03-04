//
//  UITableViewControllerDataSourceTypes.h
//  Reports
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADDriverSelectorController_h
#define Reports_MADDriverSelectorController_h

#import <UIKit/UITableViewController.h>
#import <MADExplorer/MADSaveFileProtocol.h>

extern NSString * const MTSegueShowSetUpDatasourceMySqlIdentifier;
extern NSString * const MTSegueShowSetUpDatasourceSqlite3Identifier;
extern NSString * const MTSegueShowSetUpDatasourceSalesForceIdentifier;
extern NSString * const MTSegueShowSetUpDatasourceSqlServerIdentifier;

@protocol MADViewControllerStandardProtocol;

@interface MADDriverSelectorController : UITableViewController
    <MADSaveFileProtocol>

    @property (nonatomic, weak) id <MADViewControllerStandardProtocol> delegate;
    @property (nonatomic, weak) id <MADSaveFileProtocol> saveFileDelegate;

@end

#endif
