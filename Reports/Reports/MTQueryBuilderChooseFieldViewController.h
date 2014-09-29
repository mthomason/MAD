//
//  CoreDataTableViewController.m
//  Reports
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryBuilderChooseFieldViewController_h
#define Reports_MTQueryBuilderChooseFieldViewController_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "UIViewTableSectionHeaderDatabaseTable.h"

#import "MTUnwindProtocol.h"
#import "MTQueryBuilderChooseFieldDelegate.h"

@class MTQueryBuilderChooseFieldViewController, RptqQueryField, MADocument;

@interface MTQueryBuilderChooseFieldViewController : UITableViewController
    <UITableViewDataSource,
        UITableViewDelegate,
        SectionHeaderViewDelegate,
        MTUnwindProtocol>

@property (nonatomic, weak) id <MTQueryBuilderChooseFieldDelegate> delegate;
@property (nonatomic, weak) MADocument *document;

@property (nonatomic, weak) IBOutlet UITableViewCell *fieldCells;

@property (nonatomic, strong) RptqQueryField *queryField;
@property (nonatomic, strong) NSArray *excludeTables;

@end

#endif
