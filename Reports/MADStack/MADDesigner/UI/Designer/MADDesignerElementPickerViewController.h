//
//  MADDesignerElementPIckerViewController.h
//  Reports
//
//  Created by Michael Thomason on 1/15/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADDesignerElementPIckerViewController_h
#define Reports_MADDesignerElementPIckerViewController_h

#import <UIKit/UICollectionViewController.h>
#import "MUIViewControllerDelegate.h"

#import <MAD/MADAggregateFunctionType.h>
#import <MAD/MADAggregateFunctionInputType.h>
#import <MAD/MADAggregateFunctionGroupByType.h>

extern const NSInteger MTViewTagAggregateFunctions;
extern const NSInteger MTViewTagGroupByOptions;
extern const NSInteger MTViewTagDocumentObjectNewAggregate;
extern const NSInteger MTViewTagDocumentObjectNewLabelStatic;
extern const NSInteger MTViewTagFieldOrFormulaSelector;

@class MADocument;
@class NSManagedObjectID;
@class RptqQueryField;

@protocol MADDesignerElementPickerDelegate
    <MADViewControllerStandardProtocol>

    - (void)insertDocumentObjectNewLabel:(NSString *)labelText;
    - (void)insertDocumentObjectDataField:(RptqQueryField *)field;
    - (void)insertDocumentObjectNewAggregateFunctionWithType:(MTAggregateFunctionType)functionType
                                                   inputType:(MTAggregateFunctionInputType)inputType
                                                 inputObject:(NSManagedObjectID *)inputObject
                                                   groupType:(MTAggregateGroupByType)groupType
                                                 groupNumber:(NSNumber *)groupNumber;

@end

@interface MADDesignerElementPickerViewController : UICollectionViewController

    @property (nonatomic, weak) id <MADDesignerElementPickerDelegate> objectSelectorDelegate;
    @property (nonatomic, weak) MADocument *document;

@end

#endif
