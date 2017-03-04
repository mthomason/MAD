//
//  CoreDataTableViewController.m
//  Reports
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADQueryChooseFieldController_h
#define Reports_MADQueryChooseFieldController_h

#import <UIKit/UITableViewController.h>
#import "MADUnwindProtocol.h"
#import "MADSectionHeaderViewDelegate.h"

@protocol MADQueryChooseFieldProtocol;

@class MADQueryChooseFieldController;
@class RptqQueryField;
@class MADocument;

@interface MADQueryChooseFieldController : UITableViewController
    <UITableViewDataSource,
        UITableViewDelegate,
        MADSectionHeaderViewDelegate,
        MADUnwindProtocol>

    + (instancetype)newQueryBuilderChooseFieldViewController;

    @property (nonatomic, weak) id <MADQueryChooseFieldProtocol> delegate;
    @property (nonatomic, weak) MADocument *document;

    @property (nonatomic, strong) RptqQueryField *queryField;
    @property (nonatomic, strong) NSArray *excludeTables;

@end

#endif
