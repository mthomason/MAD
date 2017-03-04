//
//  SectionEnumerator.h
//  Reports
//
//  Created by Michael Thomason on 2/14/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqDocumentSectionEnumerator_h
#define Reports_RptqDocumentSectionEnumerator_h

#import <Foundation/NSEnumerator.h>

@class NSManagedObjectID, NSManagedObjectContext, RptqDocument, NSArray;

@interface RptqDocumentSectionTypeEnumerator : NSEnumerator

    @property (nonatomic, assign) NSUInteger current;

    - (instancetype)initWithQueryID:(NSManagedObjectID *)queryID
               managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
    - (NSArray *)allObjects;
    - (id)nextObject;
    - (NSUInteger)count;

@end

@interface RptqDocumentSectionEnumerator : NSEnumerator

    @property (nonatomic, assign) NSUInteger current;

    - (instancetype)initWithDocument:(RptqDocument *)document;
    - (NSArray *)allObjects;
    - (id)nextObject;
    - (NSUInteger)count;

@end

#endif
