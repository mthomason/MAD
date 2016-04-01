//
//  NSObject+RptqDocument_Extras.h
//  Reports
//
//  Created by Michael Thomason on 2/12/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqDocument_Extras_h
#define Reports_RptqDocument_Extras_h

#import "RptqDocument.h"
#import <MADDataStructures/MTProtocolCompare.h>
#import <MAD/MADReportSectionRepresentation.h>
#import <MAD/MTPaper.h>

@class NSManagedObjectContext, MTDatabase, RptqDocumentSection, RptqDocumentObject, RptqQuery, RptqQueryPredicate, RptqQueryLinks, MADErrorContainer;

@interface RptqDocument (Extras) <MTProtocolCompare>

+ (instancetype)newDocumentForManagedObjectContext:(NSManagedObjectContext *)objectContext NS_RETURNS_RETAINED;
+ (instancetype)documentForManagedObjectContext:(NSManagedObjectContext *)objectContext;

@property (readonly)RptqDatabase *defaultDatabase;

    - (RptqDocumentSection *)documentSectionForType:(MNSDocumentSectionType)type andLevel:(NSUInteger)level;

    - (void)setNewPageAfter:(BOOL)newPageAfter forSectionAtRow:(NSUInteger)sectionRow;
    - (void)setNumberOfRows:(NSUInteger)numberOfRows forSectionAtRow:(NSUInteger)sectionRow;
    - (void)setHeight:(CGFloat)height forSectionAtRow:(NSUInteger)sectionRow;
    - (void)setVisibility:(BOOL)isVisible forSectionAtRow:(NSUInteger)sectionRow;
    - (void)addDatabase:(MTDatabase *)database forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
                 status:(void (^)(NSString *status, float progress))status
             completion:(void (^)(BOOL success, MADErrorContainer *error))completion;

    - (void)addQueryLink:(RptqQueryLinks *)queryLink;
    - (void)addPredicate:(RptqQueryPredicate *)predicate;
    - (RptqDocumentObject *)addDocumentObject:(NSDictionary *)defination;
    - (void)removeDocumentObject:(RptqDocumentObject *)documentObject;
    - (BOOL)newPageAfterSectionAtRow:(NSUInteger)sectionRow;

    - (MTPaperType)paperType;

@end

#endif
