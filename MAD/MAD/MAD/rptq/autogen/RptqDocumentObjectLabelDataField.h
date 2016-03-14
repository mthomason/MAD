//
//  RptqDocumentObjectLabelDataField.h
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_AutoGen_RptqDocumentObjectLabelDataField_h
#define MAD_AutoGen_RptqDocumentObjectLabelDataField_h

#import <CoreData/NSManagedObject.h>

@class RptqDocumentObject, RptqQueryField;

@interface RptqDocumentObjectLabelDataField : NSManagedObject

@property (nonatomic, strong) NSString * field;
@property (nonatomic, strong) NSNumber * identifier;
@property (nonatomic, strong) NSString * table;
@property (nonatomic, strong) NSString * text;
@property (nonatomic, strong) RptqDocumentObject *parentObjectLabelDataField;
@property (nonatomic, strong) RptqQueryField *referencesQueryField;

@end

#endif
