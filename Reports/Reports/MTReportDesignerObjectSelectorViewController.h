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
#import "MTDocumentObjectNewAggregateViewController.h"
#import "MTDocumentObjectNewStaticLabelViewController.h"
#import "MTGroupByViewController.h"

extern NSInteger const MTViewTagAggregateFunctions;
extern NSInteger const MTViewTagGroupByOptions;
extern NSInteger const MTViewTagDocumentObjectNewAggregate;
extern NSInteger const MTViewTagDocumentObjectNewLabelStatic;
extern NSInteger const MTViewTagFieldOrFormulaSelector;

@protocol MTReportDesignerObjectSelectorDelegate <MTViewControllerProtocol>
- (void)insertDocumentObjectNewLabel:(NSString *)labelText;
- (void)insertDocumentObjectDataField:(RptqQueryField *)field;
- (void)insertDocumentObjectNewAggregateFunctionWithType:(MTAggregateFunctionType)functionType
                                               inputType:(MTAggregateFunctionInputType)inputType
                                             inputObject:(NSManagedObjectID *)inputObject
                                               groupType:(MTAggregateGroupByType)groupType
                                             groupNumber:(NSNumber *)groupNumber;
- (void)viewControllerDidFinish:(id)sender;
@end

@interface MTReportDesignerObjectSelectorViewController : UICollectionViewController
    <MTQueryBuilderChooseFieldDelegate,
        MTAggregateFunctionsViewControllerDelegate,
        MTGroupByViewControllerDelegate,
        UINavigationControllerDelegate,
        UICollectionViewDataSource,
        UICollectionViewDelegateFlowLayout>

@property (nonatomic, assign) IBOutlet id <MTReportDesignerObjectSelectorDelegate> objectSelectorDelegate;

@end

#endif
