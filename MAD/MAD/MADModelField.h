//
//  MADModelField.h
//  MAD
//
//  Created by Michael on 2/3/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADModelField_h
#define MAD_MADModelField_h

#import <MAD/MADModel.h>

@interface MADModelField : MADModel
    <MADModelIDProtocol>
    - (instancetype)initWithIdentifier:(int64_t)identifier
                          isPrimaryKey:(BOOL)primaryKey
                              dataType:(int16_t)dataType
                        dataTypeNative:(int16_t)dataTypeNative
                              decimals:(int16_t)decimals
                                 width:(int64_t)width
                                  name:(NSString *)name;

    @property (nonatomic, weak) MADModelField *inTable;
    @property (nonatomic, readonly, copy) NSString *name;
    @property (nonatomic) BOOL primaryKey;
    @property (nonatomic) int16_t dataType;
    @property (nonatomic) int16_t dataTypeNative;
    @property (nonatomic) int16_t decimals;
    @property (nonatomic) int64_t width;

@end

#endif /* MADModelField_h */
