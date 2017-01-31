//
//  RptqDocumentElementLabel+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentElementLabel+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentElementLabel (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentElementLabel *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *text;

@end

NS_ASSUME_NONNULL_END
