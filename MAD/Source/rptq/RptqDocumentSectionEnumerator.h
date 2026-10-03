//
//  SectionEnumerator.h
//  Reports
//
//  Created by Michael Thomason on 2/14/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_RptqDocumentSectionEnumerator_h
#define Reports_RptqDocumentSectionEnumerator_h

#import <Foundation/NSEnumerator.h>
#import <MAD/RptqStoreContext.h>

@class NSManagedObjectContext, RptqDocument, NSArray;

@interface RptqDocumentSectionTypeEnumerator : NSEnumerator

	@property (nonatomic, assign) NSUInteger current;

	- (instancetype)initWithQueryID:(int64_t)queryID
			   managedObjectContext:(RptqStoreContext *)managedObjectContext;
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
