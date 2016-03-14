//
//  MNSDatabaseTable.h
//  Reports
//
//  Created by Michael Thomason on 11/18/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDatabaseTable_h
#define Reports_MTDatabaseTable_h

#import <Foundation/NSObject.h>

@interface MTDatabaseTable : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *label;
@property (nonatomic, strong) NSString *labelPlural;
@property (nonatomic, assign) BOOL queryable;

- (instancetype)initWithTableName:(NSString *)tableName NS_DESIGNATED_INITIALIZER;

@end

#endif
