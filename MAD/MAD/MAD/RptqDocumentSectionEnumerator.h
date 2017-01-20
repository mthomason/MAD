//
//  SectionEnumerator.h
//  Reports
//
//  Created by Michael Thomason on 2/14/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_SectionEnumerator_h
#define Reports_SectionEnumerator_h

#import <Foundation/NSEnumerator.h>

@class NSManagedObjectID;
@class NSManagedObjectContext;
@class RptqDocument;
@class NSArray;

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
