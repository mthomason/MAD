//
//  MADDatabaseField+Constructor.h
//  MAD
//
//  Created by Michael on 8/28/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADDatabaseField_Constructor_h
#define Reports_MADDatabaseField_Constructor_h

#import <MADAPI/MADDatabaseField.h>

@class RptqDatabaseSchemaField;

@interface MADDatabaseField (Constructor)

+ (instancetype)newDatabaseFieldWithSchemaField:(RptqDatabaseSchemaField *)schemaField;

@end

#endif
