//
//  RptqDocumentObjectLabelDataField.h
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDocumentObject, RptqField;

@interface RptqDocumentObjectLabelDataField : NSManagedObject

@property (nonatomic, retain) NSString * field;
@property (nonatomic, retain) NSString * table;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) RptqDocumentObject *parentObjectLabelDataField;
@property (nonatomic, retain) RptqField *referencesField;

@end
