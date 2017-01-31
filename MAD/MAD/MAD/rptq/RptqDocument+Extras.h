//
//  NSObject+RptqDocument_Extras.h
//  Reports
//
//  Created by Michael Thomason on 2/12/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqDocument_Extras_h
#define Reports_RptqDocument_Extras_h

#import <MAD/RptqDocument.h>
#import <MAD/MADReportSectionRepresentation.h>
#import <MAD/MTPaper.h>

@class NSManagedObjectContext;
@class MTDatabase;
@class MADErrorContainer;
@class RptqDocumentSection;
@class RptqDocumentElement;
@class RptqQuery;
@class RptqQueryPredicate;
@class RptqQueryLinks;

@interface RptqDocument (Extras)

    @property (readonly)RptqDatabase *defaultDatabase;

    @property (readonly)RptqQuery *mainQuery;

    + (instancetype)newDocumentForManagedObjectContext:(NSManagedObjectContext *)objectContext;
    + (instancetype)newDocumentReadFromManagedObjectContext:(NSManagedObjectContext *)objectContext;

    + (void)removeDocumentObject:(RptqDocumentElement *)documentObject
        fromManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

    - (RptqDocumentSection *)documentSectionForType:(MADDocumentSectionType)type
                                           andLevel:(NSUInteger)level;
    - (RptqDocumentSection *)documentSectionForSelectedIndex:(NSUInteger)selectedIndex
                                          withNumberOfGroups:(NSUInteger)numberOfGroups;
                                          
    - (void)storeDatabaseConnectionDefination:(MTDatabase *)database
                      forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
    - (MADErrorContainer *)storeTablesAndFieldsForTables:(NSArray *)tables
                                           fieldsByTable:(NSDictionary *)fieldsByTable
                                 andManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
    
    - (void)setNewPageAfter:(BOOL)newPageAfter forSectionAtRow:(NSUInteger)sectionRow;
    - (void)setNumberOfRows:(NSUInteger)numberOfRows forSectionAtRow:(NSUInteger)sectionRow;
    - (void)setHeight:(CGFloat)height forSectionAtRow:(NSUInteger)sectionRow;
    - (void)setVisibility:(BOOL)isVisible forSectionAtRow:(NSUInteger)sectionRow;
    - (void)addDatabase:(MTDatabase *)database
                        forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
                 status:(void (^)(NSString *status, float progress))status
             completion:(void (^)(BOOL success, MADErrorContainer *error))completion;

    - (void)addQueryLink:(RptqQueryLinks *)queryLink;
    - (void)addPredicate:(RptqQueryPredicate *)predicate;
    - (RptqDocumentElement *)addDocumentObject:(NSDictionary *)defination;
    - (BOOL)newPageAfterSectionAtRow:(NSUInteger)sectionRow;

    - (MTPaperType)paperType;

@end

#endif
