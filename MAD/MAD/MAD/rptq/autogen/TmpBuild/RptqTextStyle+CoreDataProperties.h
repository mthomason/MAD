//
//  RptqTextStyle+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 5/14/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqTextStyle+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface RptqTextStyle (CoreDataProperties)

+ (NSFetchRequest<RptqTextStyle *> *)fetchRequest;

@property (nonatomic) BOOL strikethrough;
@property (nonatomic) BOOL underline;
@property (nonatomic) BOOL italic;
@property (nonatomic) BOOL bold;

@end

NS_ASSUME_NONNULL_END
