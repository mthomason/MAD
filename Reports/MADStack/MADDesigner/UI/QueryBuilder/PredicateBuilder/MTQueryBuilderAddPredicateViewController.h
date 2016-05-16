//
//  UITableViewControllerSchemaAddPredicate.h
//  Reports
//
//  Created by Michael Thomason on 2/4/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryBuilderAddPredicateViewController_h
#define Reports_MTQueryBuilderAddPredicateViewController_h

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <MAD/MAD.h>
#import "MUIViewControllerDelegate.h"
#import "MTViewControllerValueBasedOnField.h"
#import "UITableViewControllerOpperators.h"

#import "MTQueryBuilderChooseFieldDelegate.h"

typedef NS_ENUM(NSUInteger, MNSPredicatePart) {
	MNSPredicateLeft = 0,
	MNSPredicateCenter,
	MNSPredicateRight,
	MNSPredicateNone
};

@class MTQueryBuilderAddPredicateViewController, RptqQueryPredicate, MADocument;

@protocol MTQueryBuilderAddPredicateDelegate
    - (void)uITableViewControllerSchemaAddPredicateDidAddPredicate:(RptqQueryPredicate *)predicate;
@end

@interface MTQueryBuilderAddPredicateViewController : UITableViewController
    <UITableViewDelegate,
        UITableViewControllerOpperatorsDelegate,
        MTQueryBuilderChooseFieldDelegate,
        MTViewControllerValueBasedOnFieldDelegate>


    @property (nonatomic, weak) IBOutlet id <MTQueryBuilderAddPredicateDelegate, MTViewControllerProtocol> delegate;
    @property (nonatomic, weak) MADocument *document;

    @property (assign) MNSPredicatePart currentlyEditingPart;

    @property (nonatomic, strong) IBOutlet UITableViewCell *tableViewCellLeftSide;
    @property (nonatomic, strong) IBOutlet UITableViewCell *tableViewCellRightSide;
    @property (nonatomic, strong) IBOutlet UITableViewCell *tableViewCellOperator;

    @property (assign) MNSPredicateOperator predicateOperator;
    @property (copy) NSString *leftValue;
    @property (copy) NSString *rightValue;
    @property (nonatomic, strong) RptqQueryField *fieldLeft;
    @property (nonatomic, strong) RptqQueryField *fieldRight;

    - (IBAction)save:(id)sender;
    - (IBAction)cancel:(id)sender;

@end

#endif
