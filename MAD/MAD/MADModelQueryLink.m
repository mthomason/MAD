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

@property (nonatomic, readwrite, strong) MADTableFieldIdentifier *leftFieldIdentifier;
@property (nonatomic, readwrite, strong) MADTableFieldIdentifier *rightFieldIdentifier;

@end

@implementation MADModelQueryLink

+ (NSFetchRequest *)fetchRequest:(NSPredicate *)predicate {
    NSFetchRequest *fetchRequest;
    
    NSUInteger expressionDescCount = 5;
    NSString *pathIdentifier, *pathHasRightField, *pathHasLeftField, *pathInQueryTable;
    
    NSExpressionDescription *expressionDescription[expressionDescCount];

    pathIdentifier = NSStringFromClass([RptqQueryLinks class]);
    
    fetchRequest = [NSFetchRequest fetchRequestWithEntityName:pathIdentifier];

    pathHasRightField = NSStringFromSelector(@selector(hasRightField));
    pathHasLeftField = NSStringFromSelector(@selector(hasLeftField));
    pathInQueryTable = NSStringFromSelector(@selector(inQueryTable));

    NSString *pathRTID = [pathHasRightField stringByAppendingString:@"."];
    pathRTID = [pathRTID stringByAppendingString:pathInQueryTable];

    NSString *pathLTID = [pathHasLeftField stringByAppendingString:@"."];
    pathLTID = [pathLTID stringByAppendingString:pathInQueryTable];

    pathIdentifier = NSStringFromSelector(@selector(identifier));

    NSString *pathRFID = [pathHasRightField stringByAppendingString:@"."];
    pathRFID = [pathRFID stringByAppendingString:pathIdentifier];
    
    NSString *pathLFID = [pathHasLeftField stringByAppendingString:@"."];
    pathLFID = [pathLFID stringByAppendingString:pathIdentifier];
    
    pathRTID = [pathRTID stringByAppendingString:@"."];
    pathRTID = [pathRTID stringByAppendingString:pathIdentifier];
    
    pathLTID = [pathLTID stringByAppendingString:@"."];
    pathLTID = [pathLTID stringByAppendingString:pathIdentifier];
    
    expressionDescription[0] = [[NSExpressionDescription alloc] init];
    expressionDescription[0].name = MADKeyQueryLinkRightFieldID;
    expressionDescription[0].expression = [NSExpression expressionForKeyPath:pathRFID];
    expressionDescription[0].expressionResultType = NSInteger64AttributeType;
    
    expressionDescription[1] = [[NSExpressionDescription alloc] init];
    expressionDescription[1].name = MADKeyQueryLinkLeftFieldID;
    expressionDescription[1].expression = [NSExpression expressionForKeyPath:pathLFID];
    expressionDescription[1].expressionResultType = NSInteger64AttributeType;

    expressionDescription[2] = [[NSExpressionDescription alloc] init];
    expressionDescription[2].name = MADKeyQueryLinkRightTableID;
    expressionDescription[2].expression = [NSExpression expressionForKeyPath:pathRTID];
    expressionDescription[2].expressionResultType = NSInteger64AttributeType;
    
    expressionDescription[3] = [[NSExpressionDescription alloc] init];
    expressionDescription[3].name = MADKeyQueryLinkLeftTableID;
    expressionDescription[3].expression = [NSExpression expressionForKeyPath:pathLTID];
    expressionDescription[3].expressionResultType = NSInteger64AttributeType;

    expressionDescription[4] = [[NSExpressionDescription alloc] init];
    expressionDescription[4].name = MADKeyQueryLinkID;
    expressionDescription[4].expression = [NSExpression expressionForKeyPath:pathIdentifier];
    expressionDescription[4].expressionResultType = NSInteger64AttributeType;

    
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

- (void)dealloc {
    _inQuery = nil;
}

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID identifier:(int64_t)identifier {
    if (self = [super initWithIdentifier:identifier]) {

    }
    return self;
}

- (instancetype)initWithIdentifier:(int64_t)identifier
                       leftFieldID:(int64_t)leftFieldID
                       leftTableID:(int64_t)leftTableID
                      rightFieldID:(int64_t)rightFieldID
                      rightTableID:(int64_t)rightTableID {
    
    if (self = [self initWithIdentifier:identifier]) {
        
        MADTableFieldIdentifier *leftFieldIdentifier, *rightFieldIdentifier;
        leftFieldIdentifier = [[MADTableFieldIdentifier alloc] initWithTableID: rightTableID
                                                                    andFieldID: rightFieldID];
        self.leftFieldIdentifier = leftFieldIdentifier;
        rightFieldIdentifier = [[MADTableFieldIdentifier alloc] initWithTableID: leftTableID
                                                                     andFieldID: leftFieldID];
        self.rightFieldIdentifier = rightFieldIdentifier;
        
    }
    return self;
}

- (NSSet <NSNumber *> *)tables {
    NSNumber *tableLeft = @(_leftFieldIdentifier.tableID),
             *tableRight = @(_rightFieldIdentifier.tableID);
    NSSet *tables = [[NSSet alloc] initWithObjects: tableLeft,
                                                    tableRight, nil];
    return tables;
}

/*- (NSSet <MADTableFieldReference *> *)tableFieldReferences {
    NSSet *tables = [[NSSet alloc] initWithObjects:_leftFieldReference,
                                                   _rightFieldReference, nil];
    return tables;
}*/

/*- (NSString *)debugDescription {
    NSString *debugDescription;
    debugDescription = self.objectID.URIRepresentation.pathComponents.count == 3 ?
    [[NSString alloc] initWithFormat:@"%@ <%@::%@> [%@ JOIN %@]",
     NSStringFromClass([self class]), self.objectID.URIRepresentation.pathComponents[1],
                                      self.objectID.URIRepresentation.pathComponents[2],
                                      _leftFieldReference.debugDescription,
                                      _rightFieldReference.debugDescription] :
                                      self.debugDescription;
    return debugDescription;
}*/

@end
