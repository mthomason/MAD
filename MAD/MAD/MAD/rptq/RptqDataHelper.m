//
//  RptqDataHelper.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqDataHelper.h"

#import <objc/objc.h>

#import <CoreFoundation/CFNumber.h>

#import <Foundation/NSObjCRuntime.h>
#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSExpression.h>

#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSExpressionDescription.h>
#import <CoreData/NSFetchRequest.h>

@implementation RptqDataHelper

+ (int64_t)nextIdentifierForClass:(Class)class
             managedObjectContext:(NSManagedObjectContext *)managedObjectContext {

    NSString *path = NSStringFromSelector(@selector(identifier));
    NSExpressionDescription *edIdentifier;
    NSFetchRequest *request;
    NSSortDescriptor *sortDescriptor;
    NSArray <NSSortDescriptor *> *sortDescriptors;
    NSArray *fetchResults;
    
    edIdentifier = [[NSExpressionDescription alloc] init];
    edIdentifier.name = @"ID";
    edIdentifier.expression = [NSExpression expressionForKeyPath:path];
    edIdentifier.expressionResultType = NSInteger64AttributeType;
    
    
    request = [[NSFetchRequest alloc] initWithEntityName: NSStringFromClass(class)];
    
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey: path
                                                 ascending: NO];
    
    sortDescriptors = [[NSArray alloc] initWithObjects: sortDescriptor, nil];
    
    NSArray *properties = [[NSArray alloc] initWithObjects:edIdentifier, nil];
    request.propertiesToFetch = properties;
    request.sortDescriptors = sortDescriptors;
    request.fetchLimit = 1;
    request.resultType = NSDictionaryResultType;
    
    NSError * __autoreleasing *error = NULL;
    fetchResults = [managedObjectContext executeFetchRequest:request error:error];
    
    //NSAssert(fetchResults.count == 0, "We expect some results.");
    
    int64_t identifier64 = 0;
    if (fetchResults.count > 0) {
        NSNumber *identifierNumber;
        if ((identifierNumber = [[fetchResults firstObject] objectForKey:@"ID"]) != nil) {
            CFNumberGetValue((__bridge CFNumberRef)(identifierNumber), kCFNumberSInt64Type, &identifier64);
        }
    }
    identifier64++;
    return identifier64;
}

- (void)identifier {
    
}

@end
