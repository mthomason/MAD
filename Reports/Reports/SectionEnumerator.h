//
//  SectionEnumerator.h
//  TheReportViewer
//
//  Created by Michael Thomason on 2/14/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIManagedDocumentQuery.h"
#import "RptqDocumentSection+Extras.h"
#import "RptqQueryGroup.h"
#import "UIManagedDocumentQuery.h"

@interface SectionEnumerator : NSEnumerator

@property (assign) NSInteger current;
@property (assign) NSInteger total;

- (id)initWithManagedDocumentQuery:(UIManagedDocumentQuery *)managedDocument;
- (NSArray *)allObjects;
- (id)nextObject;
- (NSInteger)count;

@end