//
//  RptqDocumentObjectLabelDataField+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//  This file was automatically generated and should not be edited.
//

#import "RptqDocumentObjectLabelDataField+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentObjectLabelDataField (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentObjectLabelDataField *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *field;
@property (nullable, nonatomic, copy) NSString *table;
@property (nullable, nonatomic, copy) NSString *text;
@property (nullable, nonatomic, retain) RptqDocumentObject *parentObjectLabelDataField;
@property (nullable, nonatomic, retain) RptqQueryField *referencesQueryField;

@end

NS_ASSUME_NONNULL_END
