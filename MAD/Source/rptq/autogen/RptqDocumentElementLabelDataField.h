//
//  RptqDocumentElementLabelDataField.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_RptqDocumentElementLabelDataField_h
#define MAD_RptqDocumentElementLabelDataField_h

#import <MAD/RptqDocumentElement.h>
@class RptqQueryField;

NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentElementLabelDataField : RptqDocumentElement

@end

@interface RptqDocumentElementLabelDataField (CoreDataProperties)

@property (nullable, nonatomic, copy) NSString *fieldID;
@property (nullable, nonatomic, copy) NSString *tableID;
@property (nullable, nonatomic, copy) NSString *text;
@property (nullable, nonatomic, retain) RptqQueryField *referencesQueryField;

@end

NS_ASSUME_NONNULL_END

#endif
