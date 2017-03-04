//
//  UITableViewControllerSchemaAddPredicate.h
//  Reports
//
//  Created by Michael Thomason on 2/4/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryBuilderAddPredicateViewController_h
#define Reports_MTQueryBuilderAddPredicateViewController_h

#import <UIKit/UITableViewController.h>
#import <MAD/MADPredicateOperator.h>

#import "MADViewControllerStandardProtocol.h"
#import "MADViewControllerValueBasedOnFieldDelegate.h"

#import "MADTableViewControllerOpperatorsDelegate.h"

#import "MTQueryBuilderChooseFieldDelegate.h"

typedef NS_ENUM(NSUInteger, MNSPredicatePart) {
	MNSPredicateLeft = 0,
	MNSPredicateCenter,
	MNSPredicateRight,
	MNSPredicateNone
};

@protocol MADQueryAddPredicateDelegate;

@class MADocument;

@interface MADQueryBuilderAddPredicateController : UITableViewController
    <UITableViewDelegate,
        MADTableViewControllerOpperatorsDelegate,
        MTQueryBuilderChooseFieldDelegate,
        MADViewControllerValueBasedOnFieldDelegate>


    @property (nonatomic, weak)     IBOutlet id <MADQueryAddPredicateDelegate,
                                                    MADViewControllerStandardProtocol> queryPredicateDelegate;
    @property (nonatomic, weak)     MADocument *document;

    @property (nonatomic, assign)   MNSPredicatePart currentlyEditingPart;
    @property (nonatomic, assign)   MADPredicateOperator predicateOperator;

    @property (nonatomic, weak)     IBOutlet UITableViewCell *tableViewCellLeftSide;
    @property (nonatomic, weak)     IBOutlet UITableViewCell *tableViewCellRightSide;
    @property (nonatomic, weak)     IBOutlet UITableViewCell *tableViewCellOperator;

    @property (nonatomic, copy)     NSString *leftValue;
    @property (nonatomic, copy)     NSString *rightValue;
    @property (nonatomic, strong)   RptqQueryField *fieldLeft;
    @property (nonatomic, strong)   RptqQueryField *fieldRight;

    - (IBAction)save:(id)sender;
    - (IBAction)cancel:(id)sender;

@end

#endif
