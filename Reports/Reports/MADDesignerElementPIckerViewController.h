//
//  MADDesignerElementPIckerViewController.h
//  Reports
//
//  Created by Michael Thomason on 1/15/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADDesignerElementPIckerViewController_h
#define Reports_MADDesignerElementPIckerViewController_h

#import <UIKit/UIKit.h>
#import "MUIViewControllerDelegate.h"
#import "MADAggregateGroupByType.h"
#import "MTAggregateFunctionType.h"
#import "MTAggregateFunctionInputType.h"

@class MADocument, NSManagedObjectID, RptqQueryField;

extern NSInteger const MTViewTagAggregateFunctions;
extern NSInteger const MTViewTagGroupByOptions;
extern NSInteger const MTViewTagDocumentObjectNewAggregate;
extern NSInteger const MTViewTagDocumentObjectNewLabelStatic;
extern NSInteger const MTViewTagFieldOrFormulaSelector;

@protocol MADDesignerElementPickerDelegate <MTViewControllerProtocol>
- (void)insertDocumentObjectNewLabel:(NSString *)labelText;
- (void)insertDocumentObjectDataField:(RptqQueryField *)field;
- (void)insertDocumentObjectNewAggregateFunctionWithType:(MTAggregateFunctionType)functionType
                                               inputType:(MTAggregateFunctionInputType)inputType
                                             inputObject:(NSManagedObjectID *)inputObject
                                               groupType:(MTAggregateGroupByType)groupType
                                             groupNumber:(NSNumber *)groupNumber;
- (void)viewControllerDidFinish:(id)sender;
@end

@interface MADDesignerElementPIckerViewController : UICollectionViewController

@property (nonatomic, weak) id <MADDesignerElementPickerDelegate> objectSelectorDelegate;
@property (nonatomic, weak) MADocument *document;

@end

#endif
