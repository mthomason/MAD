//
//  RptqDocumentElementLabelDataField+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqDocumentElementLabelDataField_CoreDataProperties_h
#define MAD_RptqDocumentElementLabelDataField_CoreDataProperties_h

#import "RptqDocumentElementLabelDataField.h"
#import <CoreData/NSFetchRequest.h>

NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentElementLabelDataField (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentElementLabelDataField *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *fieldID;
@property (nullable, nonatomic, copy) NSString *tableID;
@property (nullable, nonatomic, copy) NSString *text;
@property (nullable, nonatomic, retain) RptqQueryField *referencesQueryField;

@end

NS_ASSUME_NONNULL_END

#endif
