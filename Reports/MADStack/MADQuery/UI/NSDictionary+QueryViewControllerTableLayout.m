//
//  NSDictionary+QueryViewControllerTableLayout.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/25/16.
//  Copyright © 2020 Michael Thomason. All rights reserved.
//

#import "NSDictionary+QueryViewControllerTableLayout.h"
#import "MADIdentifierQueryViewSections.h"
#import "MADTableViewCellQueryTableName.h"
#import "MTAutoLayoutTableViewCell.h"
#import "MADTableViewCellQueryLink.h"

NSString * const MTTableHeaderSectionKey        = @"MTTableHeaderSectionKey";
NSString * const MTTableSectionRowKey           = @"MTTableSectionRowKey";
NSString * const MTTableSectionRowHeightKey     = @"MTTableSectionRowHeightKey";
NSString * const MTTableSectionSectionsKey      = @"MTTableSectionSectionsKey";

static NSString * const MADTextQuerySetupDatasource = @"Setup Data Source";
static NSString * const MADTextQuerySelectTables    = @"Select Tables to Use";
static NSString * const MADTextQueryReportingMode   = @"Reporting Mode";
static NSString * const MADTextQueryGroups          = @"Groups";
static NSString * const MADTextQueryPredicate       = @"Predicate";
static NSString * const MADTextQueryLinks           = @"Link the Tables";

@implementation NSDictionary (QueryViewControllerTableLayout)

+ (instancetype)newDictionaryQueryLayoutTableZeroReportingEnabled:(BOOL)reportingEnabled {
	NSNumber *one =         [[NSNumber alloc] initWithInteger: 1];
	NSNumber *unknown =     [[NSNumber alloc] initWithInteger: -1];
	NSNumber *datasource =  [[NSNumber alloc] initWithShort: MADIdentifierQueryViewSectionsDatasource];
	NSNumber *tables =      [[NSNumber alloc] initWithShort: MADIdentifierQueryViewSectionsTables];
	NSNumber *resultCount = [[NSNumber alloc] initWithShort: MADIdentifierQueryViewSectionsNumberOfQueryResults];
	NSString *h2 = NSLocalizedString(MADTextQuerySetupDatasource,   MADTextQuerySetupDatasource);
	NSString *h3 = NSLocalizedString(MADTextQuerySelectTables,      MADTextQuerySelectTables);
	NSString *h7 = NSLocalizedString(MADTextQueryReportingMode,     MADTextQueryReportingMode);
	
	NSArray *sections = reportingEnabled ?
		[[NSArray alloc] initWithObjects: datasource, tables, resultCount, nil] :
		[[NSArray alloc] initWithObjects: datasource, tables, nil];
	
	NSArray *countRowsForSection = reportingEnabled ?
		[[NSArray alloc] initWithObjects: one, unknown, one, nil] :
		[[NSArray alloc] initWithObjects: one, unknown, nil];
	
	NSDictionary *countRowsForSectionD = [[NSDictionary alloc] initWithObjects: countRowsForSection forKeys: sections];
	
	NSArray *headersSection = reportingEnabled ?
		[[NSArray alloc] initWithObjects: h2, h3, h7, nil] :
		[[NSArray alloc] initWithObjects: h2, h3, nil];
	NSDictionary *headersSectionDictionary = [[NSDictionary alloc] initWithObjects: headersSection
																		   forKeys: sections];
	NSNumber *height1 = [[NSNumber alloc] initWithDouble: 50.0],
			 *height2 = [[NSNumber alloc] initWithDouble: [MADTableViewCellQueryTableName defaultHeight]];
	NSArray *heightRowsForSectionA = reportingEnabled ?
		[[NSArray alloc] initWithObjects: height1, height2, height1, nil] :
		[[NSArray alloc] initWithObjects: height1, height2, nil];
	NSDictionary *heightRowsForSectionD;
	heightRowsForSectionD = [[NSDictionary alloc] initWithObjects: heightRowsForSectionA
														  forKeys: sections];
	id result = [[NSDictionary alloc] initWithObjectsAndKeys:
				 sections,                   MTTableSectionSectionsKey,
				 headersSectionDictionary,   MTTableHeaderSectionKey,
				 countRowsForSectionD,       MTTableSectionRowKey,
				 heightRowsForSectionD,      MTTableSectionRowHeightKey, nil];
	return result;
}

+ (instancetype)newDictionaryQueryLayoutTableOneReportingEnabled:(BOOL)reportingEnabled {
	id one =         [[NSNumber alloc] initWithInteger: 1];
	id unknown =     [[NSNumber alloc] initWithInteger: -1];
	id datasource =  [[NSNumber alloc] initWithShort: MADIdentifierQueryViewSectionsDatasource];
	id tables =      [[NSNumber alloc] initWithShort: MADIdentifierQueryViewSectionsTables];
	id resultCount = [[NSNumber alloc] initWithShort: MADIdentifierQueryViewSectionsNumberOfQueryResults];
	id h2 = NSLocalizedString(MADTextQuerySetupDatasource, MADTextQuerySetupDatasource);
	id h3 = NSLocalizedString(MADTextQuerySelectTables, MADTextQuerySelectTables);
	id h5 = NSLocalizedString(MADTextQueryGroups, MADTextQueryGroups);
	id h6 = NSLocalizedString(MADTextQueryPredicate, MADTextQueryPredicate);
	id h7 = NSLocalizedString(MADTextQueryReportingMode, MADTextQueryReportingMode);

	NSNumber *groups = [[NSNumber alloc] initWithShort: MADIdentifierQueryViewSectionsGroups];
	NSNumber *predicate = [[NSNumber alloc] initWithShort: MADIdentifierQueryViewSectionsPredicate];
	
	NSArray *sections = reportingEnabled ?
		[[NSArray alloc] initWithObjects: datasource, tables, groups, predicate, resultCount, nil] :
		[[NSArray alloc] initWithObjects: datasource, tables, groups, predicate, nil];
	
	NSArray *countRowsForSection = reportingEnabled ?
		[[NSArray alloc] initWithObjects: one, unknown, unknown, unknown, one, nil] :
		[[NSArray alloc] initWithObjects: one, unknown, unknown, unknown, nil];
	
	NSDictionary *countRowsForSectionDictionary;
	countRowsForSectionDictionary = [NSDictionary dictionaryWithObjects: countRowsForSection
																forKeys: sections];
	
	NSArray *headersSection = reportingEnabled ?
		[[NSArray alloc] initWithObjects: h2, h3, h5, h6, h7, nil] :
		[[NSArray alloc] initWithObjects: h2, h3, h5, h6, nil];
	NSDictionary *headersSectionDictionary = [NSDictionary dictionaryWithObjects: headersSection
																		 forKeys: sections];
	
	NSNumber *height1 = [[NSNumber alloc] initWithDouble: 44.0];
	NSNumber *height2 = [[NSNumber alloc] initWithDouble: [MADTableViewCellQueryTableName defaultHeight]];
	NSArray *heightRowsForSection = reportingEnabled ?
		[[NSArray alloc] initWithObjects: height1, height2, height1, height1, height1, nil] :
		[[NSArray alloc] initWithObjects: height1, height2, height1, height1, nil];
	NSDictionary *heightRowsForSectionDictionaryDictionary;
	heightRowsForSectionDictionaryDictionary = [NSDictionary dictionaryWithObjects: heightRowsForSection
																		   forKeys: sections];
	
	id result = [[NSDictionary alloc] initWithObjectsAndKeys:
				 sections, MTTableSectionSectionsKey,
				 headersSectionDictionary, MTTableHeaderSectionKey,
				 countRowsForSectionDictionary, MTTableSectionRowKey,
				 heightRowsForSectionDictionaryDictionary, MTTableSectionRowHeightKey, nil];
	return result;
}

+ (instancetype)newDictionaryQueryLayoutTableMoreThanOneReportingEnabled:(BOOL)reportingEnabled {
	NSNumber *one =         [[NSNumber alloc] initWithInteger: 1];
	NSNumber *unknown =     [[NSNumber alloc] initWithInteger: -1];
	NSNumber *datasource =  [[NSNumber alloc] initWithShort: MADIdentifierQueryViewSectionsDatasource];
	NSNumber *tables =      [[NSNumber alloc] initWithShort: MADIdentifierQueryViewSectionsTables];
	NSNumber *resultCount = [[NSNumber alloc] initWithShort: MADIdentifierQueryViewSectionsNumberOfQueryResults];
	NSNumber *links =       [[NSNumber alloc] initWithShort: MADIdentifierQueryViewSectionsLinks];
	NSNumber *groups =      [[NSNumber alloc] initWithShort: MADIdentifierQueryViewSectionsGroups];
	NSNumber *predicate =   [[NSNumber alloc] initWithShort: MADIdentifierQueryViewSectionsPredicate];

	NSString *h2 = NSLocalizedString(MADTextQuerySetupDatasource,  MADTextQuerySetupDatasource);
	NSString *h3 = NSLocalizedString(MADTextQuerySelectTables,     MADTextQuerySelectTables);
	NSString *h4 = NSLocalizedString(MADTextQueryLinks,            MADTextQueryLinks);
	NSString *h5 = NSLocalizedString(MADTextQueryGroups,           MADTextQueryGroups);
	NSString *h6 = NSLocalizedString(MADTextQueryPredicate,        MADTextQueryPredicate);
	NSString *h7 = NSLocalizedString(MADTextQueryReportingMode,    MADTextQueryReportingMode);
	
	NSArray <NSNumber *> *sections;
	sections = reportingEnabled ?
		[[NSArray alloc] initWithObjects: datasource, tables, links, groups, predicate, resultCount, nil]:
		[[NSArray alloc] initWithObjects: datasource, tables, links, groups, predicate, nil];
	
	
	NSArray <NSNumber *> *countRowsForSection;
	countRowsForSection = reportingEnabled ?
		[[NSArray alloc] initWithObjects: one, unknown, unknown, unknown, unknown, one, nil] :
		[[NSArray alloc] initWithObjects: one, unknown, unknown, unknown, unknown, nil];
	
	NSDictionary *countRowsForSectionDictionary;
	countRowsForSectionDictionary = [[NSDictionary alloc] initWithObjects: countRowsForSection
																  forKeys: sections];
	
	NSArray <NSString *> *headersSection = reportingEnabled ?
		[[NSArray alloc] initWithObjects: h2, h3, h4, h5, h6, h7, nil] :
		[[NSArray alloc] initWithObjects: h2, h3, h4, h5, h6, nil];
	
	NSDictionary <NSNumber *, NSString *> *headersSectionDictionary;
	headersSectionDictionary = [[NSDictionary alloc] initWithObjects: headersSection
															 forKeys: sections];
	NSNumber *height1 = [[NSNumber alloc] initWithDouble: 44.0],
			 *height2 = [[NSNumber alloc] initWithDouble: [MADTableViewCellQueryTableName defaultHeight]],
			 *height3 = [[NSNumber alloc] initWithDouble: [MADTableViewCellQueryLink defaultHeight]];    //50.0
	NSArray *heightRowsForSection;
		heightRowsForSection = reportingEnabled ?
			[[NSArray alloc] initWithObjects: height1, height2, height3, height1, height1, height1, nil] :
			[[NSArray alloc] initWithObjects: height1, height2, height3, height1, height1, nil];
	NSDictionary *rowHeightsBySection;
	rowHeightsBySection = [[NSDictionary alloc] initWithObjects: heightRowsForSection
														forKeys: sections];
	
	id result = [[NSDictionary alloc] initWithObjectsAndKeys:
				 sections, MTTableSectionSectionsKey,
				 headersSectionDictionary, MTTableHeaderSectionKey,
				 countRowsForSectionDictionary, MTTableSectionRowKey,
				 rowHeightsBySection, MTTableSectionRowHeightKey, nil];
	return result;
}

@end
