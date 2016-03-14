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

@class RptqDocument;

@interface RptqDocumentSectionEnumerator : NSEnumerator

@property (atomic, assign) NSUInteger current;

- (id)initWithDocument:(RptqDocument *)document;
- (NSArray *)allObjects;
- (id)nextObject;
- (NSUInteger)count;

@end

#endif
