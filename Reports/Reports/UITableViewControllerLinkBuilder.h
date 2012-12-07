//
//  UITableViewControllerLinkBuilder.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/26/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIManagedDocumentReport.h"
#import "UIViewControllerSchemaAddLinkJoinType.h"
#import "UIViewControllerSchemaAddLinkFirstTable.h"
#import "UIViewControllerSchemaAddLinkSecondTable.h"
#import "UIViewControllerSchemaAddLinkFirstField.h"
#import "UIViewControllerSchemaAddLinkSecondField.h"
#import "UITableViewControllerChooseField.h"
#import "RptqQueryLinks+Extras.h"

@class UITableViewControllerLinkBuilder;

typedef enum {
	MNSLinkLeft = 0,
	MNSLinkCenter,
	MNSLinkRight,
	MNSLinkNone
} MNSLinkPart;

@protocol UITableViewControllerLinkBuilderDelegate
- (void)viewControllerSchemaAddLinkDidFinish:(UITableViewControllerLinkBuilder *)controller;
- (void)viewControllerSchemaAddLinkDidAdd:(RptqQueryLinks *)queryLink;
@end

@interface UITableViewControllerLinkBuilder : UITableViewController
    <UITableViewDataSource, UITableViewDelegate,
        UIViewControllerSchemaAddLinkJoinTypeDelegate,
        UIViewControllerSchemaAddLinkDelegate,
        UIViewControllerSchemaAddLinkFirstFieldDelegate,
        UIViewControllerSchemaAddLinkSecondTableDelegate,
        UIViewControllerSchemaAddLinkSecondFieldDelegate,
        UITableViewControllerChooseFieldDelegate>

@property (assign, nonatomic) IBOutlet id <UITableViewControllerLinkBuilderDelegate> delegate;

@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellTableFieldOne;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellJoinType;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellTableFieldTwo;

@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellTableOne;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellFieldOne;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellTableTwo;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellFieldTwo;

@property (assign) MNSLinkPart currentlyEditingPart;

@property (copy) NSString *firstTableFieldName;
@property (assign) MNSLinkType linkType;
@property (copy) NSString *secondTableFieldName;

@property (copy) NSString *firstTableName;
@property (copy) NSString *secondTableName;
@property (copy) NSString *firstFieldName;
@property (copy) NSString *secondFieldName;

- (IBAction)done:(id)sender;
- (IBAction)save:(id)sender;
- (IBAction)cancel:(id)sender;

@end