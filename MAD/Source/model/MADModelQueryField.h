//
//  MADModelQueryField.h
//  MAD
//
//  Created by Michael on 2/3/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//
//  One field of a query table, keyed by the RptqQueryField row's identifier.  It
//  carries two ids -- the schema table and the schema field -- and resolves the
//  real metadata through the database (see -schemaField).
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
