//
//  MTDataTableFastObjectEnumerator.h
//  MAD
//
//  Created by Michael Thomason on 4/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MTDatabaseConnection;

@interface MTDataTableFastObjectEnumerator : NSEnumerator

- (id)initWithDatabaseConnection:(MTDatabaseConnection *)databaseConnection columns:(NSDictionary *)columns columnKeys:(NSArray *)columnKeys tableName:(NSString *)tableName andSortDescriptors:(NSArray *)sortDescriptors;

@end
