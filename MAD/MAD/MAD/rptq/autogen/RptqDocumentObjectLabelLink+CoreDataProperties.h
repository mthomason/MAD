//
//  RptqDocumentObjectLabelLink+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//  This file was automatically generated and should not be edited.
//

#import "RptqDocumentObjectLabelLink+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentObjectLabelLink (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentObjectLabelLink *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *text;
@property (nullable, nonatomic, copy) NSString *url;
@property (nullable, nonatomic, retain) RptqDocumentObject *parentObjectLinkLabel;

@end

NS_ASSUME_NONNULL_END
