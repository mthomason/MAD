//
//  MADDatabaseField+Constructor.h
//  MAD
//
//  Created by Michael on 8/28/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADDatabaseField_Constructor_h
#define Reports_MADDatabaseField_Constructor_h

#import <MAD/MADDatabaseField.h>

@class RptqDatabaseSchemaField;

@interface MADDatabaseField (Constructor)

    + (instancetype)newDatabaseFieldWithSchemaField:(RptqDatabaseSchemaField *)schemaField;

@end

#endif
