//
//  RptqDocumentObjectLabelDataField.h
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDocumentObject, RptqQueryField;

@interface RptqDocumentObjectLabelDataField : NSManagedObject

@property (nonatomic, strong) NSString * field;
@property (nonatomic, strong) NSNumber * identifier;
@property (nonatomic, strong) NSString * table;
@property (nonatomic, strong) NSString * text;
@property (nonatomic, strong) RptqDocumentObject *parentObjectLabelDataField;
@property (nonatomic, strong) RptqQueryField *referencesQueryField;

@end
