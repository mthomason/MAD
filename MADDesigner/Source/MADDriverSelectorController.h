//
//  UITableViewControllerDataSourceTypes.h
//  Reports
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADDriverSelectorController_h
#define Reports_MADDriverSelectorController_h

#import <MADExplorer/MADSaveFileProtocol.h>
#import <UIKit/UITableViewController.h>

@protocol MADViewControllerStandardProtocol;

@interface MADDriverSelectorController : UITableViewController <MADSaveFileProtocol>

@property (nonatomic, weak) id <MADViewControllerStandardProtocol> delegate;
@property (nonatomic, weak) id <MADSaveFileProtocol> saveFileDelegate;

@end

#endif
