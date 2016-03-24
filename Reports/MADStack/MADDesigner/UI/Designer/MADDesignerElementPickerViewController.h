//
//  MADDesignerElementPIckerViewController.h
//  Reports
//
//  Created by Michael Thomason on 1/15/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADDesignerElementPIckerViewController_h
#define Reports_MADDesignerElementPIckerViewController_h

#import <MAD/RptqDocumentObjectAggregate+Extras.h>

#import "MUIViewControllerDelegate.h"
#import "MADViewController.h"

@class MADocument, NSManagedObjectID, RptqQueryField;

extern const NSInteger MTViewTagAggregateFunctions;
extern const NSInteger MTViewTagGroupByOptions;
extern const NSInteger MTViewTagDocumentObjectNewAggregate;
extern const NSInteger MTViewTagDocumentObjectNewLabelStatic;
extern const NSInteger MTViewTagFieldOrFormulaSelector;

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

@interface MADDesignerElementPickerViewController : MADCollectionViewController

@property (nonatomic, weak) id <MADDesignerElementPickerDelegate> objectSelectorDelegate;
@property (nonatomic, weak) MADocument *document;

@end

#endif
