//
//  RptqDocumentElementLabelDataField+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MAD.RptqDocumentElementLabelDataField+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentElementLabelDataField (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentElementLabelDataField *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *field;
@property (nullable, nonatomic, copy) NSString *table;
@property (nullable, nonatomic, copy) NSString *text;
@property (nullable, nonatomic, retain) RptqQueryField *referencesQueryField;

@end

NS_ASSUME_NONNULL_END
