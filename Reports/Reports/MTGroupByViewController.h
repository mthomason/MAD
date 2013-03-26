//
//  MTGroupByViewController.h
//  Reports
//
//  Created by Michael Thomason on 3/25/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "RptqQueryGroup+Extras.h"
#import "MTActiveDocument.h"

extern NSString * const MTGroupByViewControllerIdentifier;

@interface MTGroupByViewController : UITableViewController
    <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

@end
