//
//  UITableViewControllerLinkBuilder.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/26/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIManagedDocumentQuery.h"
#import "UIViewControllerSchemaAddLinkJoinType.h"
#import "UIViewControllerSchemaAddLinkFirstTable.h"
#import "UIViewControllerSchemaAddLinkSecondTable.h"
#import "UIViewControllerSchemaAddLinkFirstField.h"
#import "UIViewControllerSchemaAddLinkSecondField.h"

@class UITableViewControllerLinkBuilder;

@protocol UITableViewControllerLinkBuilderDelegate
- (void)viewControllerSchemaAddLinkDidFinish:(UITableViewControllerLinkBuilder *)controller;
- (void)viewControllerSchemaAddLinkDidSelectFirstTableName:(NSString *)firstTable firstFieldName:(NSString *)firstFieldName secondTableName:(NSString *)secondTableName secondFieldName:(NSString *)secondFieldName withJoinType:(MNSLinkType)joinType;
@end

@interface UITableViewControllerLinkBuilder : UITableViewController
    <UITableViewDataSource, UITableViewDelegate,
        UIViewControllerSchemaAddLinkJoinTypeDelegate,
        UIViewControllerSchemaAddLinkDelegate,
        UIViewControllerSchemaAddLinkFirstFieldDelegate,
        UIViewControllerSchemaAddLinkSecondTableDelegate,
        UIViewControllerSchemaAddLinkSecondFieldDelegate>

@property (assign, nonatomic) IBOutlet id <UITableViewControllerLinkBuilderDelegate> delegate;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellJoinType;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellTableOne;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellFieldOne;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellTableTwo;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellFieldTwo;

@property (assign) MNSLinkType linkType;
@property (retain) NSString *firstTableName;
@property (retain) NSString *secondTableName;
@property (retain) NSString *firstFieldName;
@property (retain) NSString *secondFieldName;

@property (retain) UIManagedDocumentQuery *managedDocumentQuery;

- (IBAction)done:(id)sender;
- (IBAction)save:(id)sender;
- (IBAction)cancel:(id)sender;

@end