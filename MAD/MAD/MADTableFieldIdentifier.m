//
//  MADTableFieldIdentifier.m
//  MAD
//
//  Created by Michael on 2/3/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADTableFieldIdentifier.h"

#import <CoreData/NSManagedObjectID.h>

@implementation MADTableFieldIdentifier {
    int64_t _tableID;
    int64_t _fieldID;
}

@dynamic tableID;
@dynamic fieldID;

- (instancetype)init {
    if (self = [self initWithTableID:-1 andFieldID:-1]) {
    }
    return self;
}

- (instancetype)initWithTableID:(int64_t)tableID
                     andFieldID:(int64_t)fieldID {
    if (self = [super init]) {
        _tableID = tableID;
        _fieldID = fieldID;
    }
    return self;
}

- (int64_t)tableID {
    return _tableID;
}

- (int64_t)fieldID {
    return _fieldID;
}

@end

@implementation MADTableFieldReference

- (instancetype)init {
    if (self = [self initWithTableID:nil andFieldID:nil]) {
    }
    return self;
}

- (instancetype)initWithTableID:(NSManagedObjectID *)tableID
                     andFieldID:(NSManagedObjectID *)fieldID {
    if (self = [super init]) {
        _tableID = tableID.copy;
        _fieldID = fieldID.copy;
    }
    return self;
}

@end
