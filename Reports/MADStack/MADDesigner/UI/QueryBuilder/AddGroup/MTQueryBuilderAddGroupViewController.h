//
//  UITableViewControllerSchemaAddGroup.h
//  Reports
//
//  Created by Michael Thomason on 2/4/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryBuilderAddGroupViewController_h
#define Reports_MTQueryBuilderAddGroupViewController_h

#import "MTQueryBuilderSortTypeViewController.h"
#import "MTQueryBuilderChooseFieldViewController.h"
#import "MTQueryBuilderChooseFieldDelegate.h"

@class MTQueryBuilderAddGroupViewController;
@class NSManagedObjectID;
@class MADocument;

@protocol MTQueryBuilderAddGroupDelegate
- (void)addQueryGroupWithQueryField:(NSManagedObjectID *)queryField andSortOrder:(MNSSortOrder)sortOrder;
- (void)viewControllerDidCancel:(id)sender;
@end

@interface MTQueryBuilderAddGroupViewController : UITableViewController
    <UITableViewDelegate,
        MTQueryBuilderSortTypeDelegate,
        MTQueryBuilderChooseFieldDelegate>

    @property (nonatomic, weak) id <MTQueryBuilderAddGroupDelegate> delegate;
    @property (nonatomic, weak) MADocument *document;

    @property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellField;
    @property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellSort;
    @property (nonatomic, weak) IBOutlet UILabel *detailLabelField;
    @property (nonatomic, weak) IBOutlet UILabel *detailLabelSort;


    @property (copy) NSString *fieldName;
    @property (assign) MNSSortOrder sortOrder;

    - (IBAction)cancel:(id)sender;
    - (IBAction)save:(id)sender;

@end

#endif
