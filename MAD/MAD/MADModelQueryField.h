//
//  MADModelQueryField.h
//  MAD
//
//  Created by Michael on 2/3/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADModelQueryField_h
#define MAD_MADModelQueryField_h

#import <MAD/MADModel.h>

@class MADModelDatabase, MADModelQueryTable, MADModelField;

@interface MADModelQueryField : MADModel
    <MADModelIDProtocol>

    - (instancetype)initWithIdentifier:(int64_t)identifier
                           schemaTable:(int64_t)schemaTable
                           schemaField:(int64_t)schemaField
                              database:(MADModelDatabase *)database;

    @property (nonatomic, weak) MADModelQueryTable *inQueryTable;

    - (MADModelField *)schemaField;

@end

#endif /* MADModelQueryField_h */
