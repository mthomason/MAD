//
//  RptqDocumentElement+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentElement+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentElement (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentElement *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *dropIndex;
@property (nullable, nonatomic, copy) NSString *fontname;
@property (nullable, nonatomic, copy) NSNumber *fontsize;
@property (nullable, nonatomic, copy) NSNumber *identifier;
@property (nullable, nonatomic, copy) NSNumber *type;
@property (nullable, nonatomic, retain) NSObject *origin;
@property (nullable, nonatomic, retain) NSObject *dropPoint;
@property (nullable, nonatomic, retain) NSObject *margin;
@property (nullable, nonatomic, retain) NSObject *padding;
@property (nullable, nonatomic, retain) NSObject *border;
@property (nullable, nonatomic, retain) NSObject *alignment;
@property (nullable, nonatomic, retain) NSObject *size;
@property (nullable, nonatomic, retain) NSObject *style;
@property (nullable, nonatomic, retain) NSObject *backgroundColor;
@property (nullable, nonatomic, retain) NSObject *foregroundColor;
@property (nullable, nonatomic, retain) NSObject *numericFormat;
@property (nullable, nonatomic, retain) RptqDocumentSectionRows *inSectionRow;

@end

NS_ASSUME_NONNULL_END
