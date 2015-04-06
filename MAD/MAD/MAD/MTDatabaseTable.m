//
//  MNSDatabaseTable.m
//  Reports
//
//  Created by Michael Thomason on 11/18/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTDatabaseTable.h"

@implementation MTDatabaseTable

- (instancetype)initWithTableName:(NSString *)tableName {
    self = [super init];
    if (self) {
        self.name = tableName;
        self.label = tableName;
        self.labelPlural = tableName;
    }
    return self;
}

@end
