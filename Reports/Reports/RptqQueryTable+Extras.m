//
//  RptqQueryTable+Extras.m
//  Reports
//
//  Created by Michael Thomason on 3/12/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "RptqQueryTable+Extras.h"

@implementation RptqQueryTable (Extras)


#pragma mark - Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // MARK: Auto increment row counter
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQueryTable class])];
    [request setFetchLimit:1];
    NSError *error = nil;
    NSArray *fetchResults = [[self managedObjectContext] executeFetchRequest:request error:&error];
    NSUInteger identifier = 0;
    
    if (error == nil) {
        RptqDatabaseSchemaTable *lastObject = [fetchResults lastObject];
        identifier = [[lastObject identifier] integerValue] + 1;
    }
    [self setIdentifier:@(identifier)];
}

@end
