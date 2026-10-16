//
//  MADModelQueryField.h
//  MAD
//
//  Created by Michael on 2/3/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADModelQueryField_h
#define MAD_MADModelQueryField_h

#import <MAD/MADModel.h>

@class MADModelDatabase, MADModelQueryTable, MADModelField;

@interface MADModelQueryField : MADModel <MADModelIDProtocol>

@property (nonatomic, weak) MADModelQueryTable *inQueryTable;
@property (nonatomic, readonly) int64_t schemaFieldIdentifier;

- (instancetype)initWithIdentifier:(int64_t)identifier
					   schemaTable:(int64_t)schemaTable
					   schemaField:(int64_t)schemaField
						  database:(MADModelDatabase *)database;
- (MADModelField *)schemaField;
- (NSNumber *) schemaFieldID;

@end

#endif /* MADModelQueryField_h */
