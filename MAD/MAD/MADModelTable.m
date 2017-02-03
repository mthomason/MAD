//
//  MADModelTable.m
//  MAD
//
//  Created by Michael on 2/3/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADModelTable.h"

#import <Foundation/NSOrderedSet.h>
#import <Foundation/NSString.h>

#import "MADModelField.h"

@interface MADModelTable ()
    - (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                          identifier:(int64_t)identifier
                                name:(NSString *)name;
    - (void)addFieldWithID:(NSManagedObjectID *)objectID
                identifier:(int64_t)identifier
                      name:(NSString *)name
      managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
@end

#pragma mark -
#pragma mark MADModelTable

@implementation MADModelTable {
    NSString *_name;
    NSMutableOrderedSet <MADModelField *> *_fields;
}

@synthesize fields = _fields;

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID identifier:(int64_t)identifier {
    if (self = [super initWithObjectID:objectID identifier:identifier]) {

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

- (NSString *)name {
    if (_name == nil) {
        
    }
    return _name;
}

- (NSOrderedSet <MADModelField *> *)fields {
    if (_fields == nil) {
        NSMutableOrderedSet *fields = [[NSMutableOrderedSet alloc] init];
        _fields = fields;
    }
    return _fields;
}

- (void)addFieldWithID:(NSManagedObjectID *)objectID
            identifier:(int64_t)identifier
                  name:(NSString *)name
  managedObjectContext:(NSManagedObjectContext *)managedObjectContext {

    if (_fields == nil) {
        NSMutableOrderedSet *fields = [[NSMutableOrderedSet alloc] init];
        _fields = fields;
    }
    id field = [[MADModelField alloc] initWithObjectID: objectID
                                            identifier: identifier
                                                  name: name];
    [_fields addObject:field];
}

- (void)update {
    
}

- (id)debugQuickLookObject {
    NSMutableString *debug = [[NSMutableString alloc] init];
    [debug appendFormat:@"%@", NSStringFromClass([self class]).uppercaseString];
    [debug appendFormat:@"ID:\t%@\n", self.objectID];
    [debug appendFormat:@"Name:\t%@", _name];
    [debug appendFormat:@"Field:\t%@", self.fields];
    return debug;
}

@end
