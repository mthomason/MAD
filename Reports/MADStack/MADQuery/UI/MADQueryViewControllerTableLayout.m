//
//  MADQueryViewControllerTableLayout.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/11/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADQueryViewControllerTableLayout.h"
#import "MADTableViewCellQueryTableName.h"
#import "MADTableViewCellQueryLink.h"
#import "MADQuerySections.h"

static NSString * const MTTableHeaderSectionKey        = @"MTTableHeaderSectionKey";
static NSString * const MTTableSectionRowKey           = @"MTTableSectionRowKey";
static NSString * const MTTableSectionRowHeightKey     = @"MTTableSectionRowHeightKey";
static NSString * const MTTableSectionSectionsKey      = @"MTTableSectionSectionsKey";

@interface MADQueryViewControllerTableLayout ()

    @property (nonatomic, strong) NSDictionary *dataModel;

@end

@implementation MADQueryViewControllerTableLayout

- (instancetype)initWithNumberOfTables:(NSInteger)numberOfTables
                      reportingEnabled:(BOOL)reportingEnabled {
    if  (self = [super init]) {
        NSDictionary *result;
        
        NSString *h2 = NSLocalizedString(@"Setup Data Source", @"Setup Data Source");
        NSString *h3 = NSLocalizedString(@"Select Tables to Use", @"Select Tables to Use");
        NSString *h4 = NSLocalizedString(@"Link the Tables", @"Link the Tables");
        NSString *h5 = NSLocalizedString(@"Groups", @"Groups");
        NSString *h6 = NSLocalizedString(@"Predicate", @"Predicate");
        NSString *h7 = NSLocalizedString(@"Reporting Mode", @"Reporting Mode");
        
        NSNumber *one = [[NSNumber alloc] initWithInteger:1];
        NSNumber *unknown = [[NSNumber alloc] initWithInteger:-1];
        NSNumber *datasource = [[NSNumber alloc] initWithShort: MTQuerySectionsDatasource];
        NSNumber *tables = [[NSNumber alloc] initWithShort: MTQuerySectionsTables];
        NSNumber *resultCount = [[NSNumber alloc] initWithShort: MTQuerySectionsNumberOfQueryResults];
        
        switch (numberOfTables) {
            case 0: { //There are three configurations for the table.  These configurations depend
                //on the number of schemas in the query: zero, one, or more than one.
                
                NSArray *sections = reportingEnabled ? [[NSArray alloc] initWithObjects: datasource, tables, resultCount, nil] :
                [[NSArray alloc] initWithObjects: datasource, tables, nil];
                NSArray *countRowsForSection = reportingEnabled ? [[NSArray alloc] initWithObjects: one, unknown, one, nil] :
                [[NSArray alloc] initWithObjects: one, unknown, nil];
                NSDictionary *countRowsForSectionD;
                countRowsForSectionD =  [[NSDictionary alloc] initWithObjects: countRowsForSection
                                                                      forKeys: sections];
                
                NSArray *headersSection = reportingEnabled ? [[NSArray alloc] initWithObjects: h2, h3, h7, nil] :
                [[NSArray alloc] initWithObjects: h2, h3, nil];
                NSDictionary *headersSectionDictionary = [[NSDictionary alloc] initWithObjects: headersSection
                                                                                       forKeys: sections];
                NSNumber *height1 = [[NSNumber alloc] initWithDouble: 50.0000f];
                NSNumber *height2 = [[NSNumber alloc] initWithDouble: [MADTableViewCellQueryTableName defaultHeight]];
                NSArray *heightRowsForSectionA = reportingEnabled ? [[NSArray alloc] initWithObjects: height1, height2, height1, nil] :
                [[NSArray alloc] initWithObjects: height1, height2, nil];
                NSDictionary *heightRowsForSectionD;
                heightRowsForSectionD = [[NSDictionary alloc] initWithObjects: heightRowsForSectionA
                                                                      forKeys: sections];
                result = [[NSDictionary alloc] initWithObjectsAndKeys:
                          sections,                   MTTableSectionSectionsKey,
                          headersSectionDictionary,   MTTableHeaderSectionKey,
                          countRowsForSectionD,       MTTableSectionRowKey,
                          heightRowsForSectionD,      MTTableSectionRowHeightKey, nil];
                
                break;
            }
            case 1: {   //Only one table in query.  No ability to add links.
                
                NSNumber *groups = [[NSNumber alloc] initWithShort: MTQuerySectionsGroups];
                NSNumber *predicate = [[NSNumber alloc] initWithShort: MTQuerySectionsPredicate];
                
                NSArray *sections = reportingEnabled ? [[NSArray alloc] initWithObjects: datasource, tables, groups, predicate, resultCount, nil] :
                [[NSArray alloc] initWithObjects: datasource, tables, groups, predicate, nil];
                
                NSArray *countRowsForSection = reportingEnabled ? [[NSArray alloc] initWithObjects: one, unknown, unknown, unknown, one, nil] :
                [[NSArray alloc] initWithObjects: one, unknown, unknown, unknown, nil];
                NSDictionary *countRowsForSectionDictionary = [NSDictionary dictionaryWithObjects: countRowsForSection
                                                                                          forKeys: sections];
                
                NSArray *headersSection = reportingEnabled ? [[NSArray alloc] initWithObjects: h2, h3, h5, h6, h7, nil] :
                [[NSArray alloc] initWithObjects: h2, h3, h5, h6, nil];
                NSDictionary *headersSectionDictionary = [NSDictionary dictionaryWithObjects: headersSection
                                                                                     forKeys: sections];
                
                NSNumber *height1 = [[NSNumber alloc] initWithDouble: 44.0000f];
                NSNumber *height2 = [[NSNumber alloc] initWithDouble: [MADTableViewCellQueryTableName defaultHeight]];
                NSArray *heightRowsForSection = reportingEnabled ? [[NSArray alloc] initWithObjects: height1, height2, height1, height1, height1, nil] :
                [[NSArray alloc] initWithObjects: height1, height2, height1, height1, nil];
                NSDictionary *heightRowsForSectionDictionaryDictionary = [NSDictionary dictionaryWithObjects: heightRowsForSection
                                                                                                     forKeys: sections];
                
                result = [[NSDictionary alloc] initWithObjectsAndKeys:
                          sections, MTTableSectionSectionsKey,
                          headersSectionDictionary, MTTableHeaderSectionKey,
                          countRowsForSectionDictionary, MTTableSectionRowKey,
                          heightRowsForSectionDictionaryDictionary, MTTableSectionRowHeightKey, nil];
                
                break;
            }
            default: {   //Two more more tables in query.  All features available.
                
                NSNumber *links = [[NSNumber alloc] initWithShort: MTQuerySectionsLinks];
                NSNumber *groups = [[NSNumber alloc] initWithShort: MTQuerySectionsGroups];
                NSNumber *predicate = [[NSNumber alloc] initWithShort: MTQuerySectionsPredicate];
                
                NSArray *sections;
                if (reportingEnabled) {
                    sections = [[NSArray alloc] initWithObjects: datasource, tables, links, groups, predicate, resultCount, nil];
                } else {
                    sections = [[NSArray alloc] initWithObjects: datasource, tables, links, groups, predicate, nil];
                }
                
                NSArray *countRowsForSection = reportingEnabled ? [[NSArray alloc] initWithObjects: one, unknown, unknown, unknown, unknown, one, nil] :
                [[NSArray alloc] initWithObjects: one, unknown, unknown, unknown, unknown, nil];
                NSDictionary *countRowsForSectionDictionary = [[NSDictionary alloc] initWithObjects: countRowsForSection
                                                                                            forKeys: sections];
                
                NSArray *headersSection = reportingEnabled ? [[NSArray alloc] initWithObjects: h2, h3, h4, h5, h6, h7, nil] :
                [[NSArray alloc] initWithObjects: h2, h3, h4, h5, h6, nil];
                NSDictionary *headersSectionDictionary = [[NSDictionary alloc] initWithObjects: headersSection
                                                                                       forKeys: sections];
                NSNumber *height1 = [[NSNumber alloc] initWithDouble: 44.0000f];
                NSNumber *height2 = [[NSNumber alloc] initWithDouble: [MADTableViewCellQueryTableName defaultHeight]];
                NSNumber *height3 = [[NSNumber alloc] initWithDouble: [MADTableViewCellQueryLink defaultHeight]];    //50.0000f
                NSArray *heightRowsForSection;
                if (reportingEnabled) {
                    heightRowsForSection = [[NSArray alloc] initWithObjects: height1, height2, height3,
                                            height1, height1,
                                            height1, nil];
                } else {
                    heightRowsForSection = [[NSArray alloc] initWithObjects: height1, height2, height3,
                                            height1, height1, nil];
                }
                NSDictionary *rowHeightsBySection;
                rowHeightsBySection = [[NSDictionary alloc] initWithObjects:heightRowsForSection
                                                                    forKeys:sections];
                
                result = [[NSDictionary alloc] initWithObjectsAndKeys:
                          sections, MTTableSectionSectionsKey,
                          headersSectionDictionary, MTTableHeaderSectionKey,
                          countRowsForSectionDictionary, MTTableSectionRowKey,
                          rowHeightsBySection, MTTableSectionRowHeightKey, nil];
                
                break;
            }
        }
        self.dataModel = result;
    }
    return self;
}

- (NSArray *)sectionTypes {
    id sections = self.dataModel[MTTableSectionSectionsKey];
    NSArray *sectionTypes = sections != nil ?
                    [NSArray arrayWithArray: sections] :
                    nil;
    return sectionTypes;
}

@end
