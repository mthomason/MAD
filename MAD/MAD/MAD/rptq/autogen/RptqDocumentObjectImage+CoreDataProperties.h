//
//  RptqDocumentObjectImage+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentObjectImage+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@class UIImage;

@interface RptqDocumentObjectImage (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentObjectImage *> *)fetchRequest;

@property (nullable, nonatomic, retain) UIImage *image;
@property (nullable, nonatomic, retain) RptqDocumentObject *parentObject;

@end

NS_ASSUME_NONNULL_END
