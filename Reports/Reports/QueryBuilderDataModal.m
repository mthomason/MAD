//
//  QueryBuilderDataModal.m
//  TheReportViewer
//
//  Created by Michael Thomason on 3/2/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "QueryBuilderDataModal.h"
#import "UIManagedDocumentQuery.h"
#import "Constants.h"
#import "UITableViewCellInstruction.h"
#import "UITableViewCellTableName.h"
#import "UITableViewCellQueryLink.h"
#import "UITableViewCellQueryInput.h"
#import "RptqQueryTables+Extras.h"

@interface QueryBuilderDataModal ()

@property (retain) NSMutableDictionary *modelWithZeroTables;
@property (retain) NSMutableDictionary *modelWithOneTable;
@property (retain) NSMutableDictionary *modelWithTwoOrMoreTables;

@end

@implementation QueryBuilderDataModal

@synthesize modelWithZeroTables = _modelWithZeroTables, modelWithOneTable = _modelWithOneTable, modelWithTwoOrMoreTables = _modelWithTwoOrMoreTables;

- (void)dealloc {
    [_modelWithZeroTables release];
    [_modelWithOneTable release];
    [_modelWithTwoOrMoreTables release];
    [super dealloc];
}

- (id)initWithManagedDocumentQuery:(UIManagedDocumentQuery *)managedDocument {
    self = [super init];
    if (self) {
        
        NSString *h1 = NSLocalizedString(@"Layout", @"Layout");
        NSString *h2 = NSLocalizedString(@"Setup Data Source", @"Setup Data Source");
        NSString *h3 = NSLocalizedString(@"Select Tables to Use", @"Select Tables to Use");
        NSString *h4 = NSLocalizedString(@"Link the Tables", @"Link the Tables");
        NSString *h5 = NSLocalizedString(@"Groups", @"Groups");
        NSString *h6 = NSLocalizedString(@"Predicate", @"Predicate");
        NSString *h7 = NSLocalizedString(@"Override the SQL", @"Override the SQL");
        
        
        NSArray *sections = [[NSArray alloc] initWithObjects:
                             [NSNumber numberWithInteger:UIViewControllerSchemaTablesSectionsDatasource],
                             [NSNumber numberWithInteger:UIViewControllerSchemaTablesSectionsTables],
                             [NSNumber numberWithInteger:UIViewControllerSchemaTablesSectionsInstructions],
                             nil];
        
        NSArray *countRowsForSection = [[NSArray alloc] initWithObjects:
                                        [NSNumber numberWithInteger: 1],
                                        [NSNumber numberWithInteger: -1],
                                        [NSNumber numberWithInteger: -1],
                                        nil];
        
        NSDictionary *countRowsForSectionDictionary = [[NSDictionary alloc] initWithObjects: countRowsForSection
                                                                                    forKeys: sections];
        
        NSArray *headersSection = [[NSArray alloc] initWithObjects: h2, h3, h1, nil];
        NSDictionary *headersSectionDictionary = [[NSDictionary alloc] initWithObjects: headersSection
                                                                               forKeys: sections];
        
        
        
        
        NSArray *heightRowsForSection = [[NSArray alloc] initWithObjects:
                                         [NSNumber numberWithFloat: 44.0000f],
                                         [NSNumber numberWithFloat: [UITableViewCellTableName defaultHeight]],
                                         [NSNumber numberWithFloat: [UITableViewCellInstruction defaultHeight]],
                                         nil];
        NSDictionary *heightRowsForSectionDictionaryDictionary = [[NSDictionary alloc] initWithObjects: heightRowsForSection
                                                                                               forKeys: sections];
        
        
        
        
        NSDictionary *tableOutline = [[NSDictionary alloc] initWithObjectsAndKeys:
                                      sections, KEY_TBL_SEC_SECTIONS,
                                      headersSectionDictionary, KEY_TBL_SEC_HEADERS,
                                      countRowsForSectionDictionary, KEY_TBL_SEC_ROW_COUNT,
                                      heightRowsForSectionDictionaryDictionary, KEY_TBL_SEC_ROW_HEIGHT, nil];
        
        
        [self setModelWithZeroTables: [NSMutableDictionary dictionaryWithDictionary:tableOutline]];
        
        [tableOutline release];
        tableOutline = nil;
        [heightRowsForSectionDictionaryDictionary release];
        heightRowsForSectionDictionaryDictionary = nil;
        [heightRowsForSection release];
        heightRowsForSection = nil;
        
        
        
        
        [headersSectionDictionary release];
        headersSectionDictionary = nil;
        [headersSection release];
        headersSection = nil;
        
        [countRowsForSectionDictionary release];
        countRowsForSectionDictionary = nil;
        
        [countRowsForSection release];
        countRowsForSection = nil;
        
        [sections release];
        sections = nil;
        
        
        sections = [[NSArray alloc] initWithObjects:
                    [NSNumber numberWithInteger:UIViewControllerSchemaTablesSectionsDatasource],
                    [NSNumber numberWithInteger:UIViewControllerSchemaTablesSectionsTables],
                    [NSNumber numberWithInteger:UIViewControllerSchemaTablesSectionsGroups],
                    [NSNumber numberWithInteger:UIViewControllerSchemaTablesSectionsPredicate],
                    [NSNumber numberWithInteger:UIViewControllerSchemaTablesSectionsInstructions],
                    nil];
        
        countRowsForSection = [[NSArray alloc] initWithObjects:
                               [NSNumber numberWithInteger: 1],
                               [NSNumber numberWithInteger: -1],
                               [NSNumber numberWithInteger: -1],
                               [NSNumber numberWithInteger: -1],
                               [NSNumber numberWithInteger: -1],
                               nil];
        
        headersSection = [[NSArray alloc] initWithObjects: h2, h3, h5, h6, h1, nil];
        headersSectionDictionary = [[NSDictionary alloc] initWithObjects: headersSection
                                                                 forKeys: sections];
        
        countRowsForSectionDictionary = [[NSDictionary alloc] initWithObjects: countRowsForSection
                                                                      forKeys: sections];
        
        heightRowsForSection = [[NSArray alloc] initWithObjects:
                                [NSNumber numberWithFloat: 44.0000f],
                                [NSNumber numberWithFloat: [UITableViewCellTableName defaultHeight]],
                                [NSNumber numberWithFloat: 44.0000f],
                                [NSNumber numberWithFloat: 44.0000f],
                                [NSNumber numberWithFloat: [UITableViewCellInstruction defaultHeight]],
                                nil];
        heightRowsForSectionDictionaryDictionary = [[NSDictionary alloc] initWithObjects: heightRowsForSection
                                                                                 forKeys: sections];
        
        
        
        tableOutline = [[NSDictionary alloc] initWithObjectsAndKeys:
                        sections, KEY_TBL_SEC_SECTIONS,
                        headersSectionDictionary, KEY_TBL_SEC_HEADERS,
                        countRowsForSectionDictionary, KEY_TBL_SEC_ROW_COUNT,
                        heightRowsForSectionDictionaryDictionary, KEY_TBL_SEC_ROW_HEIGHT, nil];
        
        
        [self setModelWithOneTable: [NSMutableDictionary dictionaryWithDictionary:tableOutline]];
        
        [tableOutline release];
        tableOutline = nil;
        [headersSectionDictionary release];
        headersSectionDictionary = nil;
        [headersSection release];
        headersSection = nil;
        [heightRowsForSectionDictionaryDictionary release];
        heightRowsForSectionDictionaryDictionary = nil;
        [heightRowsForSection release];
        heightRowsForSection = nil;
        [countRowsForSectionDictionary release];
        countRowsForSectionDictionary = nil;
        [countRowsForSection release];
        countRowsForSection = nil;
        [sections release];
        sections = nil;
        
        sections = [[NSArray alloc] initWithObjects:
                    [NSNumber numberWithInteger:UIViewControllerSchemaTablesSectionsDatasource],
                    [NSNumber numberWithInteger:UIViewControllerSchemaTablesSectionsTables],
                    [NSNumber numberWithInteger:UIViewControllerSchemaTablesSectionsLinks],
                    [NSNumber numberWithInteger:UIViewControllerSchemaTablesSectionsGroups],
                    [NSNumber numberWithInteger:UIViewControllerSchemaTablesSectionsPredicate],
                    [NSNumber numberWithInteger:UIViewControllerSchemaTablesSectionsInstructions],
                    nil];
        
        countRowsForSection = [[NSArray alloc] initWithObjects:
                               [NSNumber numberWithInteger: 1],
                               [NSNumber numberWithInteger: -1],
                               [NSNumber numberWithInteger: -1],
                               [NSNumber numberWithInteger: -1],
                               [NSNumber numberWithInteger: -1],
                               [NSNumber numberWithInteger: -1],
                               nil];
        
        headersSection = [[NSArray alloc] initWithObjects: h2, h3, h4, h5, h6, h1, nil];
        headersSectionDictionary = [[NSDictionary alloc] initWithObjects: headersSection
                                                                 forKeys: sections];
        countRowsForSectionDictionary = [[NSDictionary alloc] initWithObjects: countRowsForSection
                                                                      forKeys: sections];


        
        
        heightRowsForSection = [[NSArray alloc] initWithObjects:
                                [NSNumber numberWithFloat: 44.0000f],
                                [NSNumber numberWithFloat: [UITableViewCellTableName defaultHeight]],
                                [NSNumber numberWithFloat: [UITableViewCellQueryLink defaultHeight]],
                                [NSNumber numberWithFloat: 44.0000f],
                                [NSNumber numberWithFloat: 44.0000f],
                                [NSNumber numberWithFloat: [UITableViewCellInstruction defaultHeight]],
                                nil];
        heightRowsForSectionDictionaryDictionary = [[NSDictionary alloc] initWithObjects: heightRowsForSection
                                                                                 forKeys: sections];
        
        
        tableOutline = [[NSDictionary alloc] initWithObjectsAndKeys:
                        sections, KEY_TBL_SEC_SECTIONS,
                        headersSectionDictionary, KEY_TBL_SEC_HEADERS,
                        countRowsForSectionDictionary, KEY_TBL_SEC_ROW_COUNT,
                        heightRowsForSectionDictionaryDictionary, KEY_TBL_SEC_ROW_HEIGHT, nil];
        
        
        [self setModelWithTwoOrMoreTables: [NSMutableDictionary dictionaryWithDictionary:tableOutline]];
        
        [tableOutline release];
        tableOutline = nil;
        [headersSectionDictionary release];
        headersSectionDictionary = nil;
        [headersSection release];
        headersSection = nil;
        [heightRowsForSectionDictionaryDictionary release];
        heightRowsForSectionDictionaryDictionary = nil;
        [heightRowsForSection release];
        heightRowsForSection = nil;
        [countRowsForSectionDictionary release];
        countRowsForSectionDictionary = nil;
        [countRowsForSection release];
        countRowsForSection = nil;
        [sections release];
        sections = nil;

    }
    return self;
}

- (NSMutableDictionary *)datamodel {
    return [self datamodelForNumberOfTables:[RptqQueryTables countForManagedObjectContext:[[UIManagedDocumentQuery activeDocument] managedObjectContext]]];
}

- (NSMutableDictionary *)datamodelForNumberOfTables:(NSInteger)numberOfTables {
    NSMutableDictionary *result;
    switch (numberOfTables) {
        case 0:
            result = [[[self modelWithZeroTables] retain] autorelease];
            break;
        case 1:
            result = [[[self modelWithOneTable] retain] autorelease];
            break;
        default:
            result = [[[self modelWithTwoOrMoreTables] retain] autorelease];
            break;
    }
    return result;
}

@end