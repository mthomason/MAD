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
    - (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                          identifier:(int64_t)identifier
                                name:(NSString *)name;

@end

#pragma mark -
#pragma mark MADModelField

@implementation MADModelField {
    NSString *_name;
}

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID identifier:(int64_t)identifier {
    if (self = [super initWithObjectID: objectID identifier: identifier]) {

    }
    return self;
}

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                      identifier:(int64_t)identifier
                            name:(NSString *)name {
    if (self = [self initWithObjectID:objectID identifier:identifier]) {
        _name = name.copy;
    }
    return self;
}

/*- (id)debugQuickLookObject {
    NSMutableString *debug = [[NSMutableString alloc] init];
    [debug appendFormat:@"%@", NSStringFromClass([self class]).uppercaseString];
    [debug appendFormat:@"ID:\t%@\n", self.objectID];
    [debug appendFormat:@"Name:\t%@", _name];
    return debug;
}*/

@end
