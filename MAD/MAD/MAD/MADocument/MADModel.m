//
//  MADModel.m
//  MAD
//
//  Created by Michael on 1/22/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADModel.h"
#import <CoreFoundation/CFTree.h>
#import <CoreData/NSManagedObjectID.h>
#import <CoreData/NSExpressionDescription.h>
#import <CoreData/NSEntityDescription.h>
#import <CoreData/NSFetchedResultsController.h>
#import <CoreData/NSManagedObjectID.h>
#import <CoreData/NSFetchedPropertyDescription.h>
#import <CoreData/NSPropertyDescription.h>
#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSAttributeDescription.h>
#import <Foundation/NSCompoundPredicate.h>
#import <Foundation/NSPredicate.h>
#import <Foundation/NSComparisonPredicate.h>
#import <Foundation/NSExpression.h>
#import <Foundation/NSOrderedSet.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSException.h>
#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSKeyValueCoding.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSMapTable.h>
#import <Foundation/NSOperation.h>
#import <MAD/RptqDocument.h>
#import <MAD/RptqDatabase.h>
#import <MAD/RptqQuery.h>
#import <MAD/RptqQueryTable.h>
#import <MAD/RptqQueryLinks.h>
#import <MAD/RptqQueryField.h>
#import <MAD/RptqDatabaseSchemaTable.h>
#import <MAD/RptqDatabaseSchemaField.h>

#import "MADModelDocument.h"
#import "MADModelDatabase.h"

#import <stdlib.h>

NSString * const MADNotificationQueryTableInsert = @"MADNotificationQueryTableInsert";
NSString * const MADNotificationQueryTableDelete = @"MADNotificationQueryTableDelete";

NSString * const MADNotificationQueryLinkInsert = @"MADNotificationQueryLinkInsert";
NSString * const MADNotificationQueryLinkDelete = @"MADNotificationQueryLinkDelete";

NSString * const MADKeyQueryLink = @"QL";
NSString * const MADKeyQueryLinkLeftField = @"LF";
NSString * const MADKeyQueryLinkRightField = @"RF";
NSString * const MADKeyQueryLinkLeftTable = @"LT";
NSString * const MADKeyQueryLinkRightTable = @"RT";
NSString * const MADKeyQueryTable = @"QT";
NSString * const MADKeyQueryField = @"QF";
NSString * const MADKeySchemaFieldName = @"SFN";
NSString * const MADKeySchemaTableName = @"STN";
NSString * const MADKeySchemaTable = @"ST";
NSString * const MADKeySchemaField = @"SF";

NSString * const MADKeyQueryLinkID = @"QLI";
NSString * const MADKeyQueryLinkLeftFieldID = @"LFI";
NSString * const MADKeyQueryLinkRightFieldID = @"RFI";
NSString * const MADKeyQueryLinkLeftTableID = @"LTI";
NSString * const MADKeyQueryLinkRightTableID = @"RTI";

NSString * const MADKeyQueryTableID = @"QTI";
NSString * const MADKeyQueryFieldID = @"QFI";
NSString * const MADKeySchemaTableID = @"STI";
NSString * const MADKeySchemaFieldID = @"SFI";

NSString * const MADKeyQuery = @"MADKeyQuery";

#pragma mark -
#pragma mark MAD Object ID

@implementation MADModel {
  @protected
    int64_t _uid;
}
    @dynamic identifier;
    @synthesize objectID = _objectID;

+ (instancetype)newModelDocument:(NSManagedObjectContext *)managedObjectContext {
    return [[MADModelDocument alloc] initWithContext:managedObjectContext];
}

- (instancetype)init {
    return self = [self initWithObjectID:nil identifier:-1];
}

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                      identifier:(int64_t)identifier {
    if (self = [super init]) {
        _objectID = objectID.copy;
        _uid = identifier;
    }
    return self;
}

- (int64_t)identifier {
    return _uid;
}

- (NSUInteger)hash {
    return 2654435761U * (unsigned long)llabs(_uid)^2;
}

- (BOOL)isEqual:(id)object {

    return (self == object || (object != nil &&
            [object isKindOfClass:[self class]] &&
            ((typeof(self))object).identifier == _uid));
    
}

- (NSString *)debugDescription {
    NSString *debugDescription;
    debugDescription = _objectID.URIRepresentation.pathComponents.count == 3 ?
                            [[NSString alloc] initWithFormat:@"%@ <%@::%@> %@, %@, $@, %@",
                             NSStringFromClass([self class]),
                             _objectID.URIRepresentation.pathComponents[1],
                             _objectID.URIRepresentation.pathComponents[2],
                             _objectID.URIRepresentation.absoluteString,
                             _objectID.URIRepresentation.relativeString,
                             _objectID.URIRepresentation.dataRepresentation] :
                            self.debugDescription;
    return debugDescription;
}

@end
