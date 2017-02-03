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
#import <Foundation/NSURL.h>

@interface MADModelQueryField ()

@end

@implementation MADModelQueryField {
    NSManagedObjectID *_schemaField;
}

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID identifier:(int64_t)identifier {
    if (self = [super initWithObjectID:objectID identifier:identifier]) {
        
    }
    return self;
}

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                      identifier:(int64_t)identifier
                     schemaField:(NSManagedObjectID *)schemaField
           schemaFieldIdentifier:(int64_t)schemaFieldIdentifier {
    if (self = [self initWithObjectID: objectID identifier:identifier]) {
        _schemaField = schemaField.copy;
    }
    return self;
}

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

@end

