//
//  MADModelField.h
//  MAD
//
//  Created by Michael on 2/3/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  One schema field, keyed by the RptqDatabaseSchemaField row's identifier: name,
//  data type and the width/decimals metadata.  Built by MADModelTable -update.
//  The `inTable` back-pointer is declared but never assigned (docs/project/MADModel_Layer.md §6).
//

#ifndef MAD_MADModelField_h
#define MAD_MADModelField_h

#import <MAD/MADModel.h>

@interface MADModelField : MADModel <MADModelIDProtocol>

@property (nonatomic, weak) MADModelField *inTable;
@property (nonatomic, readonly, copy) NSString *name;
@property (nonatomic) BOOL primaryKey;
@property (nonatomic) int16_t dataType;
@property (nonatomic) int16_t dataTypeNative;
@property (nonatomic) int16_t decimals;
@property (nonatomic) int64_t width;

- (instancetype)initWithIdentifier:(int64_t)identifier
					  isPrimaryKey:(BOOL)primaryKey
						  dataType:(int16_t)dataType
					dataTypeNative:(int16_t)dataTypeNative
						  decimals:(int16_t)decimals
							 width:(int64_t)width
							  name:(NSString *)name;

@end

#endif /* MADModelField_h */
