//
//  RptqQueryLinks+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//  This file was automatically generated and should not be edited.
//

#import "RptqQueryLinks+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface RptqQueryLinks (CoreDataProperties)

+ (NSFetchRequest<RptqQueryLinks *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *designerInitalLayout;
@property (nullable, nonatomic, copy) NSNumber *designerOriginX;
@property (nullable, nonatomic, copy) NSNumber *designerOriginY;
@property (nullable, nonatomic, copy) NSNumber *designerSizeHeight;
@property (nullable, nonatomic, copy) NSNumber *designerSizeWidth;
@property (nullable, nonatomic, copy) NSString *fieldleft;
@property (nullable, nonatomic, copy) NSString *fieldright;
@property (nullable, nonatomic, copy) NSNumber *identifier;
@property (nullable, nonatomic, copy) NSString *jointype;
@property (nullable, nonatomic, copy) NSNumber *jointypeenum;
@property (nullable, nonatomic, copy) NSString *tableleft;
@property (nullable, nonatomic, copy) NSString *tableright;
@property (nullable, nonatomic, retain) RptqQueryField *hasLeftField;
@property (nullable, nonatomic, retain) RptqQueryField *hasRightField;
@property (nullable, nonatomic, retain) RptqQuery *inQuery;

@end

NS_ASSUME_NONNULL_END
