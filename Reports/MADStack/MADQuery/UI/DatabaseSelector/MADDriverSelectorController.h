//
//  UITableViewControllerDataSourceTypes.h
//  Reports
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MADDriverSelectorController_h
#define Reports_MADDriverSelectorController_h

#import <UIKit/UITableViewController.h>
#import <MADExplorer/MADSaveFileProtocol.h>

@protocol MADViewControllerStandardProtocol;

@interface MADDriverSelectorController : UITableViewController
    <MADSaveFileProtocol>

    @property (nonatomic, weak) id <MADViewControllerStandardProtocol> delegate;
    @property (nonatomic, weak) id <MADSaveFileProtocol> saveFileDelegate;

@end

#endif
