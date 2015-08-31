//
//  NSObject+RptqDocument_Extras.h
//  Reports
//
//  Created by Michael Thomason on 2/12/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqDocument_Extras_h
#define Reports_RptqDocument_Extras_h

#import <Foundation/Foundation.h>
#import "RptqDocument.h"
#import "MTProtocolCompare.h"
#import "RptqDocumentSection+Extras.h"

@class NSManagedObjectContext, MTDatabase, RptqQuery, RptqQueryPredicate, RptqQueryLinks, MTErrorContainer;

@interface RptqDocument (Extras) <MTProtocolCompare>

+ (instancetype)documentFactory:(NSManagedObjectContext *)objectContext;
+ (instancetype)documentForManagedObjectContext:(NSManagedObjectContext *)objectContext;

@property (readonly) RptqQuery *query;  //Default... works for one query reports.
- (RptqQuery *)defaultQuery;
- (RptqDatabase *)defaultDatabase;

- (RptqDocumentSection *)documentSectionForType:(MNSDocumentSectionType)type andLevel:(NSUInteger)level;

- (void)setNewPageAfter:(BOOL)newPageAfter forSectionAtRow:(NSInteger)sectionRow;
- (void)setNumberOfRows:(NSUInteger)numberOfRows forSectionAtRow:(NSUInteger)sectionRow;
- (void)setHeight:(CGFloat)height forSectionAtRow:(NSUInteger)sectionRow;
- (void)setVisibility:(BOOL)isVisible forSectionAtRow:(NSUInteger)sectionRow;
- (void)addDatabase:(MTDatabase *)database status:(void (^)(NSString *status, CGFloat progress))status
         completion:(void (^)(BOOL success, MTErrorContainer *error))completion;

- (void)addQueryLink:(RptqQueryLinks *)queryLink;
- (void)addPredicate:(RptqQueryPredicate *)predicate;
- (RptqDocumentObject *)addDocumentObject:(NSDictionary *)defination;
- (void)removeDocumentObject:(RptqDocumentObject *)documentObject;
- (BOOL)newPageAfterSectionAtRow:(NSInteger)sectionRow;

@end

#endif
