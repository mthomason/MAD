//
//  UITableViewControllerSchemaAddPredicate.h
//  TheReportViewer
//
//  Created by Michael Thomason on 2/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RptqQueryPredicate.h"
#import "UITableViewControllerOpperators.h"
#import "UIManagedDocumentQuery.h"
#import "UITableViewControllerChooseField.h"
#import "UITableViewControllerEnterString.h"

typedef enum {
	MNSPredicateLeft = 0,
	MNSPredicateCenter,
	MNSPredicateRight,
	MNSPredicateNone
} MNSPredicatePart;

@class UITableViewControllerSchemaAddPredicate;

@protocol UITableViewControllerSchemaAddPredicateDelegate
- (void)uITableViewControllerSchemaAddPredicateDidFinish:(UITableViewControllerSchemaAddPredicate *)controller;
- (void)uITableViewControllerSchemaAddPredicateDidAddPredicate:(RptqQueryPredicate *)predicate;
@optional
- (void)uITableViewControllerSchemaAddPredicateWithLeft:(NSString *)leftField comparson:(MNSPredicateOperator)comparsonOperator andRightValue:(NSString *)rightValue;
@end

@interface UITableViewControllerSchemaAddPredicate : UITableViewController
    <UITableViewDelegate,
        UITableViewControllerOpperatorsDelegate,
        UITableViewControllerChooseFieldDelegate,
        UITableViewControllerEnterStringDelegate>

@property (assign, nonatomic) IBOutlet id <UITableViewControllerSchemaAddPredicateDelegate> delegate;

@property (assign) MNSPredicatePart currentlyEditingPart;

@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellLeftSide;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellRightSide;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellOperator;

@property (assign) MNSPredicateOperator predicateOperator;
@property (retain) NSString *leftValue;
@property (retain) NSString *rightValue;


@property (retain) UIManagedDocumentQuery *managedDocumentQuery;

- (IBAction)save:(id)sender;
- (IBAction)cancel:(id)sender;

@end