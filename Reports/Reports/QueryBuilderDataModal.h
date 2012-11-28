//
//  QueryBuilderDataModal.h
//  TheReportViewer
//
//  Created by Michael Thomason on 3/2/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
	UIViewControllerSchemaTablesSectionsInstructions = 0,
    UIViewControllerSchemaTablesSectionsDatasource = 1,
	UIViewControllerSchemaTablesSectionsTables = 2,
	UIViewControllerSchemaTablesSectionsLinks = 3,
	UIViewControllerSchemaTablesSectionsGroups = 4,
	UIViewControllerSchemaTablesSectionsPredicate = 5,
    UIViewControllerSchemaTablesSectionsSql = 6
} UIViewControllerSchemaTablesSections;

@class UIManagedDocumentReport;

@interface QueryBuilderDataModal : NSObject

- (id)initWithManagedDocumentQuery:(UIManagedDocumentReport *)managedDocument;

- (NSMutableDictionary *)datamodel;
- (NSMutableDictionary *)datamodelForNumberOfTables:(NSInteger)numberOfTables;

@end