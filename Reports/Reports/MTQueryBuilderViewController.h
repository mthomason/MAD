//
//  UIViewControllerSchemaTables.h
//  Reports
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryBuilderViewController_h
#define Reports_MTQueryBuilderViewController_h

#import <UIKit/UIKit.h>
#import "MUIViewControllerDelegate.h"

@class MAReportDocument;

extern NSString * const NSFetchedResultsCacheName;
extern NSString * const NSFetchedResultsCacheTables;
extern NSString * const NSFetchedResultsCacheLinks;
extern NSString * const NSFetchedResultsCacheGroups;
extern NSString * const NSFetchedResultsCachePredicates;

@interface MTQueryBuilderViewController : UITableViewController

@property (nonatomic, weak) IBOutlet id <MTViewControllerProtocol> delegate;
@property (nonatomic, weak) MAReportDocument *document;

@property BOOL debug;

- (void)reloadDocument:(MAReportDocument *)documentReport animated:(BOOL)animated;

- (IBAction)edit:(id)sender;

@end

#endif
