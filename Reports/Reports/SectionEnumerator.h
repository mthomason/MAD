//
//  SectionEnumerator.h
//  Reports
//
//  Created by Michael Thomason on 2/14/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_SectionEnumerator_h
#define Reports_SectionEnumerator_h

#import <Foundation/Foundation.h>
#import "RptqDocumentSection+Extras.h"
#import "RptqQueryGroup.h"

@interface SectionEnumerator : NSEnumerator

@property (assign) NSInteger current;
@property (assign) NSInteger total;

- (id)initWithDocument:(RptqDocument *)document;
- (NSArray *)allObjects;
- (id)nextObject;
- (NSInteger)count;

@end

#endif
