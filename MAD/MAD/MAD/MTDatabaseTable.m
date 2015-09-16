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

@interface MTDatabaseTable ()

- (instancetype)init NS_DESIGNATED_INITIALIZER;

@end

@implementation MTDatabaseTable

- (instancetype)init {
    if (self = [super init]) {
        self.name = nil;
        self.label = nil;
        self.labelPlural = nil;
    }
    return self;
}

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
