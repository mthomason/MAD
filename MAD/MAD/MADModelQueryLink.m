//
//  MADModelQueryLink.m
//  MAD
//
//  Created by Michael on 2/3/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADModelQueryLink.h"

#import <CoreData/NSExpressionDescription.h>
#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectID.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSExpression.h>
#import <Foundation/NSURL.h>

#import "MADTableFieldIdentifier.h"

#import "RptqQueryLinks.h"
#import "RptqQueryField.h"

@interface MADModelQueryLink ()

@end

@implementation MADModelQueryLink {
    MADTableFieldReference *_leftFieldReference;
    MADTableFieldReference *_rightFieldReference;
    MADTableFieldIdentifier *_leftFieldIdentifier;
    MADTableFieldIdentifier *_rightFieldIdentifier;
}

+ (NSFetchRequest *)fetchRequest:(NSPredicate *)predicate {
    NSFetchRequest *fetchRequest;
    
    NSUInteger expressionDescCount = 10;
    NSString *pathIdentifier, *pathHasRightField, *pathHasLeftField, *pathInQueryTable;
    
    NSExpressionDescription *expressionDescription[expressionDescCount];

    pathIdentifier = NSStringFromClass([RptqQueryLinks class]);
    
    fetchRequest = [NSFetchRequest fetchRequestWithEntityName:pathIdentifier];

    pathHasRightField = NSStringFromSelector(@selector(hasRightField));
    pathHasLeftField = NSStringFromSelector(@selector(hasLeftField));
    pathInQueryTable = NSStringFromSelector(@selector(inQueryTable));

    expressionDescription[0] = [[NSExpressionDescription alloc] init];
    expressionDescription[0].name = MADKeyQueryLink;
    expressionDescription[0].expression = [NSExpression expressionForEvaluatedObject];
    expressionDescription[0].expressionResultType = NSManagedObjectIDResultType;

    NSString *pathRTID = [pathHasRightField stringByAppendingString:@"."];
    pathRTID = [pathRTID stringByAppendingString:pathInQueryTable];

    NSString *pathLTID = [pathHasLeftField stringByAppendingString:@"."];
    pathLTID = [pathLTID stringByAppendingString:pathInQueryTable];

    expressionDescription[1] = [[NSExpressionDescription alloc] init];
    expressionDescription[1].name = MADKeyQueryLinkLeftTable;
    expressionDescription[1].expression = [NSExpression expressionForKeyPath:pathRTID];
    expressionDescription[1].expressionResultType = NSObjectIDAttributeType;
    
    expressionDescription[2] = [[NSExpressionDescription alloc] init];
    expressionDescription[2].name = MADKeyQueryLinkLeftField;
    expressionDescription[2].expression = [NSExpression expressionForKeyPath:pathHasLeftField];
    expressionDescription[2].expressionResultType = NSObjectIDAttributeType;
    
    expressionDescription[3] = [[NSExpressionDescription alloc] init];
    expressionDescription[3].name = MADKeyQueryLinkRightTable;
    expressionDescription[3].expression = [NSExpression expressionForKeyPath:pathLTID];
    expressionDescription[3].expressionResultType = NSObjectIDAttributeType;
    
    expressionDescription[4] = [[NSExpressionDescription alloc] init];
    expressionDescription[4].name = MADKeyQueryLinkRightField;
    expressionDescription[4].expression = [NSExpression expressionForKeyPath:pathHasRightField];
    expressionDescription[4].expressionResultType = NSObjectIDAttributeType;
    
    pathIdentifier = NSStringFromSelector(@selector(identifier));

    NSString *pathRFID = [pathHasRightField stringByAppendingString:@"."];
    pathRFID = [pathRFID stringByAppendingString:pathIdentifier];
    
    NSString *pathLFID = [pathHasLeftField stringByAppendingString:@"."];
    pathLFID = [pathLFID stringByAppendingString:pathIdentifier];
    
    pathRTID = [pathRTID stringByAppendingString:@"."];
    pathRTID = [pathRTID stringByAppendingString:pathIdentifier];
    
    pathLTID = [pathLTID stringByAppendingString:@"."];
    pathLTID = [pathLTID stringByAppendingString:pathIdentifier];
    
    expressionDescription[5] = [[NSExpressionDescription alloc] init];
    expressionDescription[5].name = MADKeyQueryLinkRightFieldID;
    expressionDescription[5].expression = [NSExpression expressionForKeyPath:pathRFID];
    expressionDescription[5].expressionResultType = NSInteger64AttributeType;
    
    expressionDescription[6] = [[NSExpressionDescription alloc] init];
    expressionDescription[6].name = MADKeyQueryLinkLeftFieldID;
    expressionDescription[6].expression = [NSExpression expressionForKeyPath:pathLFID];
    expressionDescription[6].expressionResultType = NSInteger64AttributeType;

    expressionDescription[7] = [[NSExpressionDescription alloc] init];
    expressionDescription[7].name = MADKeyQueryLinkRightTableID;
    expressionDescription[7].expression = [NSExpression expressionForKeyPath:pathRTID];
    expressionDescription[7].expressionResultType = NSInteger64AttributeType;
    
    expressionDescription[8] = [[NSExpressionDescription alloc] init];
    expressionDescription[8].name = MADKeyQueryLinkLeftTableID;
    expressionDescription[8].expression = [NSExpression expressionForKeyPath:pathLTID];
    expressionDescription[8].expressionResultType = NSInteger64AttributeType;

    expressionDescription[9] = [[NSExpressionDescription alloc] init];
    expressionDescription[9].name = MADKeyQueryLinkID;
    expressionDescription[9].expression = [NSExpression expressionForKeyPath:pathIdentifier];
    expressionDescription[9].expressionResultType = NSInteger64AttributeType;

    
    NSArray <NSExpressionDescription *> *properties;
    properties = [[NSArray alloc] initWithObjects: expressionDescription
                                            count: expressionDescCount];
    fetchRequest.propertiesToFetch = properties;
    fetchRequest.resultType = NSDictionaryResultType;
    fetchRequest.predicate = predicate;

    for (NSUInteger i=0; i<expressionDescCount; i++) {
        expressionDescription[i] = nil;
    }
    
    return fetchRequest;
}

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID identifier:(int64_t)identifier {
    if (self = [super initWithObjectID:objectID identifier:identifier]) {

    }
    return self;
}

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                      identifier:(int64_t)identifier
                     leftFieldID:(NSManagedObjectID *)leftFieldID
                    lfIdentifier:(int64_t)lfIdentifier
                     leftTableID:(NSManagedObjectID *)leftTableID
                    ltIdentifier:(int64_t)ltIdentifier
                    rightFieldID:(NSManagedObjectID *)rightFieldID
                    rfIdentifier:(int64_t)rfIdentifier
                    rightTableID:(NSManagedObjectID *)rightTableID
                    rtIdentifier:(int64_t)rtIdentifier {
    
    if (self = [self initWithObjectID:objectID identifier:identifier]) {
        
        MADTableFieldIdentifier *leftFieldIdentifier, *rightFieldIdentifier;
        leftFieldIdentifier = [[MADTableFieldIdentifier alloc] initWithTableID: rtIdentifier
                                                                    andFieldID: rfIdentifier];
        _leftFieldIdentifier = leftFieldIdentifier;
        rightFieldIdentifier = [[MADTableFieldIdentifier alloc] initWithTableID: ltIdentifier
                                                                     andFieldID: lfIdentifier];
        _rightFieldIdentifier = rightFieldIdentifier;
        
        MADTableFieldReference *leftFieldReference;
        leftFieldReference = [[MADTableFieldReference alloc] initWithTableID: leftTableID
                                                                  andFieldID: leftFieldID];
        _leftFieldReference = leftFieldReference;
        
        id rightFieldReference = [[MADTableFieldReference alloc] initWithTableID: rightTableID
                                                                      andFieldID: rightFieldID];
        _rightFieldReference = rightFieldReference;
    }
    return self;
}

- (NSString *)debugDescription {
    NSString *debugDescription;
    debugDescription = self.objectID.URIRepresentation.pathComponents.count == 3 ?
    [[NSString alloc] initWithFormat:@"%@ <%@::%@> [%@ JOIN %@]",
     NSStringFromClass([self class]), self.objectID.URIRepresentation.pathComponents[1],
                                      self.objectID.URIRepresentation.pathComponents[2],
                                      _leftFieldReference.debugDescription,
                                      _rightFieldReference.debugDescription] :
                                      self.debugDescription;
    return debugDescription;
}

- (NSSet <NSManagedObjectID *> *)tables {
    NSManagedObjectID *tableLeft = _leftFieldReference.tableID.copy,
                      *tableRight = _rightFieldReference.tableID.copy;
    NSSet *tables = [[NSSet alloc] initWithObjects: tableLeft,
                                                    tableRight, nil];
    return tables;
}

- (NSSet <MADTableFieldReference *> *)tableFieldReferences {
    NSSet *tables = [[NSSet alloc] initWithObjects:_leftFieldReference,
                                                   _rightFieldReference, nil];
    return tables;
}

@end
