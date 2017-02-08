//
//  MADModelField.m
//  MAD
//
//  Created by Michael on 2/3/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADModelField.h"

#import <Foundation/NSString.h>

@interface MADModelField ()

@end

#pragma mark -
#pragma mark MADModelField

@implementation MADModelField {
    NSString *_name;
    BOOL _primaryKey;
    int16_t _dataType;
    int16_t _dataTypeNative;
    int16_t _decimals;
    int64_t _width;
}

@dynamic name;
@dynamic primaryKey;
@dynamic dataType;
@dynamic dataTypeNative;
@dynamic decimals;
@dynamic width;

- (instancetype)initWithIdentifier:(int64_t)identifier {
    if (self = [super initWithIdentifier: identifier]) {

    }
    return self;
}

- (instancetype)initWithIdentifier:(int64_t)identifier
                      isPrimaryKey:(BOOL)primaryKey
                          dataType:(int16_t)dataType
                    dataTypeNative:(int16_t)dataTypeNative
                          decimals:(int16_t)decimals
                             width:(int64_t)width
                              name:(NSString *)name {
    if (self = [self initWithIdentifier:identifier]) {
        _name = name.copy;
        _primaryKey = primaryKey;
        _dataType = dataType;
        _dataTypeNative = dataTypeNative;
        _decimals = decimals;
        _width = width;
    }
    return self;
}

- (NSString *)name {
    return _name;
}

- (BOOL)primaryKey {
    return _primaryKey;
}

- (int16_t)dataType {
    return _dataType;
}

- (int16_t)dataTypeNative {
    return _dataTypeNative;
}
- (int16_t)decimals {
    return _decimals;
}

- (int64_t)width {
    return _width;
}

/*- (id)debugQuickLookObject {
    NSMutableString *debug = [[NSMutableString alloc] init];
    [debug appendFormat:@"%@", NSStringFromClass([self class]).uppercaseString];
    [debug appendFormat:@"ID:\t%@\n", self.objectID];
    [debug appendFormat:@"Name:\t%@", _name];
    return debug;
}*/

@end
