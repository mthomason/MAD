//
//  MTReportDesignerObjectSelectorViewController.h
//  Reports
//
//  Created by Michael Thomason on 1/15/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTReportDesignerObjectSelectorViewController_h
#define Reports_MTReportDesignerObjectSelectorViewController_h

#import <UIKit/UIKit.h>
#import "MTViewController.h"
#import "MTQueryBuilderChooseFieldViewController.h"
#import "AppDelegate.h"
#import "MTDocumentObjectNewAggregateViewController.h"
#import "MTDocumentObjectNewStaticLabelViewController.h"
#import "MTGroupByViewController.h"
#import "RptqDocumentObjectFormula+Extras.h"
#import "RptqDocumentObjectAggregate+Extras.h"

@protocol MTReportDesignerObjectSelectorDelegate <MUIViewControllerProtocol>
- (void)insertDocumentObjectDataField:(RptqDatabaseSchemaField *)field;
- (void)insertDocumentObjectNewLabel:(NSString *)labelText;
- (void)insertDocumentObjectNewFormula;
- (void)insertDocumentObjectNewChart;
- (void)insertDocumentObjectNewHyperlink;
- (void)insertDocumentObjectNewAggregateFunctionWithType:(MTAggregateFunctionType)functionType
                                               inputType:(MTAggregateFunctionInputType)inputType
                                             inputObject:(NSManagedObjectID *)inputObject
                                               groupType:(MTGroupByType)groupType
                                             groupNumber:(NSNumber *)groupNumber;
- (void)viewControllerDidFinish:(id)sender;
@end

@interface MTReportDesignerObjectSelectorViewController : MTViewController
    <MTQueryBuilderChooseFieldDelegate,
        MTAggregateFunctionsViewControllerDelegate,
        MTGroupByViewControllerDelegate,
        UINavigationControllerDelegate,
        UIImagePickerControllerDelegate,
        UICollectionViewDataSource,
        UICollectionViewDelegateFlowLayout,
        UITableViewDelegate>

@property (nonatomic, assign) IBOutlet id <MTReportDesignerObjectSelectorDelegate> objectSelectorDelegate;

@end

#endif
