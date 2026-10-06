//
//  CoreDataTableViewController.m
//  Reports
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MADQueryChooseFieldController_h
#define Reports_MADQueryChooseFieldController_h

#import <UIKit/UITableViewController.h>
#import "MADUnwindProtocol.h"
#import "MADSectionHeaderViewDelegate.h"

@protocol MADQueryChooseFieldProtocol;

@class MADQueryChooseFieldController, MADocument;

@interface MADQueryChooseFieldController : UITableViewController <UITableViewDataSource, UITableViewDelegate, MADSectionHeaderViewDelegate, MADUnwindProtocol>

@property (nonatomic, weak) id <MADQueryChooseFieldProtocol> delegate;
@property (nonatomic, weak) MADocument *document;

@property (nonatomic, assign) int64_t queryFieldID;
@property (nonatomic, strong) NSArray <NSString *> *excludeTables;

+ (instancetype)newQueryBuilderChooseFieldViewController;

@end

#endif
