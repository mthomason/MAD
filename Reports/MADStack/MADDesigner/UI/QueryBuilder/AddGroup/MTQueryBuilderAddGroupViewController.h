//
//  UITableViewControllerSchemaAddGroup.h
//  Reports
//
//  Created by Michael Thomason on 2/4/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryBuilderAddGroupViewController_h
#define Reports_MTQueryBuilderAddGroupViewController_h

#import <UIKit/UITableViewController.h>
#import "MADQueryBuilderSortTypeDelegate.h"
#import "MADQueryChooseFieldProtocol.h"

@protocol MADQueryBuilderAddGroupDelegate;

@class MTQueryBuilderAddGroupViewController, MADocument;

@interface MTQueryBuilderAddGroupViewController : UITableViewController
    <UITableViewDelegate,
        MADQueryBuilderSortTypeDelegate,
        MADQueryChooseFieldProtocol>

    @property (nonatomic, weak) id <MADQueryBuilderAddGroupDelegate> delegate;
    @property (nonatomic, weak) MADocument *document;

    @property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellField;
    @property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellSort;
    @property (nonatomic, weak) IBOutlet UILabel *detailLabelField;
    @property (nonatomic, weak) IBOutlet UILabel *detailLabelSort;


    @property (nonatomic, copy) NSString *fieldName;
    @property (nonatomic, assign) MADSortOrder sortOrder;

    - (IBAction)cancel:(id)sender;
    - (IBAction)save:(id)sender;

@end

#endif
