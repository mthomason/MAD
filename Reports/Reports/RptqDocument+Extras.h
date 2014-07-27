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

@class NSManagedObjectContext, MTDatabase, RptqQuery;

@interface RptqDocument (Extras) <MTProtocolCompare>

- (RptqQuery *)defaultQuery;
- (RptqDatabase *)defaultDatabase;

+ (RptqDocument *)documentFactory:(NSManagedObjectContext *)objectContext;
+ (RptqDocument *)documentForManagedObjectContext:(NSManagedObjectContext *)objectContext;

- (RptqDocumentSection *)documentSectionForType:(MNSDocumentSectionType)type andLevel:(NSUInteger)level;
- (NSDictionary *)layoutHeightsBySectionKey;

- (void)setNumberOfRows:(NSUInteger)numberOfRows forSectionAtRow:(NSUInteger)sectionRow;
- (void)setHeight:(CGFloat)height forSectionAtRow:(NSUInteger)sectionRow;
- (void)setVisibility:(BOOL)isVisible forSectionAtRow:(NSUInteger)sectionRow;
- (void)addDatabase:(MTDatabase *)database
             status:(void (^)(NSString *readStatus))status
         completion:(void (^)(BOOL success, NSError *error))completion;

@end

#endif
