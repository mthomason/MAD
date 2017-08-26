//
//  MADModelQueryField.m
//  MAD
//
//  Created by Michael on 2/3/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADModelQueryField.h"

#import <CoreData/NSManagedObjectID.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSURL.h>

#import "MADModelDatabase.h"
#import "MADModelTable.h"
#import "MADModelField.h"

@interface MADModelQueryField ()

@end

@implementation MADModelQueryField {
    MADModelDatabase * __weak _database;
    int64_t _schemaTable;
    int64_t _schemaField;
}

- (void)dealloc {
    _database = nil;
    _inQueryTable = nil;
}

- (instancetype)initWithIdentifier:(int64_t)identifier {
    if (self = [super initWithIdentifier:identifier]) { }
    return self;
}

- (instancetype)initWithIdentifier:(int64_t)identifier
                       schemaTable:(int64_t)schemaTable
                       schemaField:(int64_t)schemaField
                          database:(MADModelDatabase *)database {
    if (self = [self initWithIdentifier:identifier]) {
        _database = database;
        _schemaTable = schemaTable;
        _schemaField = schemaField;
    }
    return self;
}

- (MADModelField *)schemaField {
    NSNumber *keyTable = @(_schemaTable), *keyField = @(_schemaField);
    MADModelTable *table = [_database.tableDictionary objectForKey:keyTable];
    MADModelField *field = [table.fields objectForKey:keyField];
    return field;
}

- (int64_t) schemaFieldIdentifier {
    return _schemaField;
}

- (NSNumber *) schemaFieldID {
    return @(_schemaField);
}
/*
- (NSString *)debugDescription {
    NSString *debugDescription;
    debugDescription = self.objectID.URIRepresentation.pathComponents.count == 3 ?
    [[NSString alloc] initWithFormat:@"%@ <%@::%@>",
     NSStringFromClass([self class]),
     self.objectID.URIRepresentation.pathComponents[1],
     self.objectID.URIRepresentation.pathComponents[2]] :
    self.debugDescription;
    return debugDescription;
}
*/
@end

