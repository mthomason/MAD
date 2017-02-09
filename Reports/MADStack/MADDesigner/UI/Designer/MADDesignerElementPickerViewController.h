//
//  MADDesignerElementPIckerViewController.h
//  Reports
//
//  Created by Michael Thomason on 1/15/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADDesignerElementPIckerViewController_h
#define Reports_MADDesignerElementPIckerViewController_h

#import "MADCollectionViewController.h"
#import "MADViewControllerStandardProtocol.h"

#import <MAD/MADAggregateFunctionType.h>
#import <MAD/MADAggregateFunctionInputType.h>
#import <MAD/MADAggregateFunctionGroupByType.h>

@class MADocument, NSManagedObjectID, RptqQueryField;

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

@interface MADDesignerElementPickerViewController : MADCollectionViewController

    @property (nonatomic, weak) id <MADDesignerElementPickerDelegate> objectSelectorDelegate;
    @property (nonatomic, weak) MADocument *document;

@end

#endif
