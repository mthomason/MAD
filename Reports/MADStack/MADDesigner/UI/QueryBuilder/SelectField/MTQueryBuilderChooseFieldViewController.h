//
//  CoreDataTableViewController.m
//  Reports
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryBuilderChooseFieldViewController_h
#define Reports_MTQueryBuilderChooseFieldViewController_h

#import <UIKit/UITableViewController.h>
#import "MTUnwindProtocol.h"
#import "MADSectionHeaderViewDelegate.h"

@protocol MTQueryBuilderChooseFieldDelegate;

@class MTQueryBuilderChooseFieldViewController;
@class RptqQueryField;
@class MADocument;

@interface MTQueryBuilderChooseFieldViewController : UITableViewController
    <UITableViewDataSource,
        UITableViewDelegate,
        MADSectionHeaderViewDelegate,
        MTUnwindProtocol>

    + (instancetype)newQueryBuilderChooseFieldViewController;

    @property (nonatomic, weak) id <MTQueryBuilderChooseFieldDelegate> delegate;
    @property (nonatomic, weak) MADocument *document;

    @property (nonatomic, strong) RptqQueryField *queryField;
    @property (nonatomic, strong) NSArray *excludeTables;

@end

#endif
