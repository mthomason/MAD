//
//  MADElementPickerProtocol.h
//  MAD Designer
//
//  Created by Michael on 2/16/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADElementPickerProtocol_h
#define MADElementPickerProtocol_h

#import <MAD/MADAggregateFunctionType.h>
#import <MAD/MADAggregateFunctionInputType.h>
#import <MAD/MADAggregateFunctionGroupByType.h>
#import <MADAPI/MADViewControllerStandardProtocol.h>

@protocol MADElementPickerProtocol <MADViewControllerStandardProtocol>

- (void)insertDocumentObjectNewLabel:(NSString *)labelText;
- (void)insertDocumentObjectWhitespace;
- (void)insertDocumentObjectDataField:(RptqQueryField *)field;
- (void)insertDocumentObjectNewAggregateFunctionWithType:(MTAggregateFunctionType)functionType
											   inputType:(MTAggregateFunctionInputType)inputType
											 inputObject:(int64_t)inputObject
											   groupType:(MTAggregateGroupByType)groupType
											 groupNumber:(NSNumber *)groupNumber;

@end

#endif /* MADElementPickerProtocol_h */
