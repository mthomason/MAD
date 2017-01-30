//
//  RptqDocumentElementLabelLink+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentElementLabelLink+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentElementLabelLink (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentElementLabelLink *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *text;
@property (nullable, nonatomic, copy) NSString *url;

@end

NS_ASSUME_NONNULL_END
