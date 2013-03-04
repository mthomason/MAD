//
//  MNSDatabaseTable.h
//  Reports
//
//  Created by Michael Thomason on 11/18/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MTDatabaseTable : NSObject

- (id)initWithTableName:(NSString *)tableName;

@property (copy) NSString *name;
@property (copy) NSString *label;
@property (copy) NSString *labelPlural;
@property (assign) BOOL queryable;

@end
