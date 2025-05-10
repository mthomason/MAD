//
//  MADQueryViewControllerTableLayout.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/11/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADQueryViewControllerTableLayout.h"
#import "MADTableViewCellQueryTableName.h"
#import "MADTableViewCellQueryLink.h"
#import "MADIdentifierQueryViewSections.h"
#import "MADQueryViewDataSource.h"

#import <UIKit/UITableView.h>

static NSString * const MADTextQuerySetupDatasource = @"Setup Data Source";
static NSString * const MADTextQuerySelectTables    = @"Select Tables to Use";
static NSString * const MADTextQueryReportingMode   = @"Reporting Mode";
static NSString * const MADTextQueryGroups          = @"Groups";
static NSString * const MADTextQueryPredicate       = @"Predicate";
static NSString * const MADTextQueryLinks           = @"Link the Tables";

@interface MADQueryViewControllerTableLayout ()

@property (nonatomic, copy) NSArray<NSNumber *> *sections;
@property (nonatomic, copy) NSDictionary<NSNumber *, NSString *> *headersBySection;
@property (nonatomic, copy) NSDictionary<NSNumber *, NSArray <NSNumber *> *> *rowCountsBySection;
@property (nonatomic, copy) NSDictionary<NSNumber *, NSArray <NSNumber *> *> *rowHeightsBySection;

@end

@implementation MADQueryViewControllerTableLayout

- (instancetype)initWithNumberOfTables:(NSInteger)numberOfTables
					  reportingEnabled:(BOOL)enabled {
	
	self = [super init];
	if (!self) return nil;
	
	switch (numberOfTables) {
		case 0:
			[self setupLayoutForZeroTablesWithReporting:enabled];
			break;
		case 1:
			[self setupLayoutForOneTableWithReporting:enabled];
			break;
		default:
			[self setupLayoutForMultipleTablesWithReporting:enabled];
			break;
	}
	
	return self;
}

#pragma mark - Public Methods

- (NSArray *)sectionTypes {
	return [self.sections copy];
}

#pragma mark - Layout Configurations

- (void)setupLayoutForZeroTablesWithReporting:(BOOL)reportingEnabled {
	NSNumber *one = @1;
	NSNumber *unknown = @-1;
	
	NSNumber *datasource = @(MADIdentifierQueryViewSectionsDatasource);
	NSNumber *tables = @(MADIdentifierQueryViewSectionsTables);
	NSNumber *resultCount = @(MADIdentifierQueryViewSectionsNumberOfQueryResults);
	
	NSArray *sections = reportingEnabled ? @[datasource, tables, resultCount] : @[datasource, tables];
	NSArray *rowCounts = reportingEnabled ? @[one, unknown, one] : @[one, unknown];
	NSArray *headers = reportingEnabled ?
	@[NSLocalizedString(MADTextQuerySetupDatasource, MADTextQuerySetupDatasource),
	  NSLocalizedString(MADTextQuerySelectTables, MADTextQuerySelectTables),
	  NSLocalizedString(MADTextQueryReportingMode, MADTextQueryReportingMode)] :
	@[NSLocalizedString(MADTextQuerySetupDatasource, MADTextQuerySetupDatasource),
	  NSLocalizedString(MADTextQuerySelectTables, MADTextQuerySelectTables)];
	
	NSNumber *height1 = @50.0;
	NSNumber *height2 = @([MADTableViewCellQueryTableName defaultHeight]);
	NSArray *heights = reportingEnabled ? @[height1, height2, height1] : @[height1, height2];
	
	self.sections = sections;
	self.rowCountsBySection = [NSDictionary dictionaryWithObjects:rowCounts forKeys:sections];
	self.headersBySection = [NSDictionary dictionaryWithObjects:headers forKeys:sections];
	self.rowHeightsBySection = [NSDictionary dictionaryWithObjects:heights forKeys:sections];
}

- (void)setupLayoutForOneTableWithReporting:(BOOL)reportingEnabled {
	NSNumber *one = @1;
	NSNumber *unknown = @-1;
	
	NSNumber *datasource = @(MADIdentifierQueryViewSectionsDatasource);
	NSNumber *tables = @(MADIdentifierQueryViewSectionsTables);
	NSNumber *groups = @(MADIdentifierQueryViewSectionsGroups);
	NSNumber *predicate = @(MADIdentifierQueryViewSectionsPredicate);
	NSNumber *resultCount = @(MADIdentifierQueryViewSectionsNumberOfQueryResults);
	
	NSArray *sections = reportingEnabled ?
	@[datasource, tables, groups, predicate, resultCount] :
	@[datasource, tables, groups, predicate];
	NSArray *rowCounts = reportingEnabled ?
	@[one, unknown, unknown, unknown, one] :
	@[one, unknown, unknown, unknown];
	
	NSArray *headers = reportingEnabled ?
	@[NSLocalizedString(MADTextQuerySetupDatasource, MADTextQuerySetupDatasource),
	  NSLocalizedString(MADTextQuerySelectTables, MADTextQuerySelectTables),
	  NSLocalizedString(MADTextQueryGroups, MADTextQueryGroups),
	  NSLocalizedString(MADTextQueryPredicate, MADTextQueryPredicate),
	  NSLocalizedString(MADTextQueryReportingMode, MADTextQueryReportingMode)] :
	@[NSLocalizedString(MADTextQuerySetupDatasource, MADTextQuerySetupDatasource),
	  NSLocalizedString(MADTextQuerySelectTables, MADTextQuerySelectTables),
	  NSLocalizedString(MADTextQueryGroups, MADTextQueryGroups),
	  NSLocalizedString(MADTextQueryPredicate, MADTextQueryPredicate)];
	
	NSNumber *height1 = @44.0;
	NSNumber *height2 = @([MADTableViewCellQueryTableName defaultHeight]);
	NSArray *heights = reportingEnabled ?
	@[height1, height2, height1, height1, height1] :
	@[height1, height2, height1, height1];
	
	self.sections = sections;
	self.rowCountsBySection = [NSDictionary dictionaryWithObjects:rowCounts forKeys:sections];
	self.headersBySection = [NSDictionary dictionaryWithObjects:headers forKeys:sections];
	self.rowHeightsBySection = [NSDictionary dictionaryWithObjects:heights forKeys:sections];
}

- (void)setupLayoutForMultipleTablesWithReporting:(BOOL)reportingEnabled {
	NSNumber *one = @1;
	NSNumber *unknown = @-1;
	
	NSNumber *datasource = @(MADIdentifierQueryViewSectionsDatasource);
	NSNumber *tables = @(MADIdentifierQueryViewSectionsTables);
	NSNumber *links = @(MADIdentifierQueryViewSectionsLinks);
	NSNumber *groups = @(MADIdentifierQueryViewSectionsGroups);
	NSNumber *predicate = @(MADIdentifierQueryViewSectionsPredicate);
	NSNumber *resultCount = @(MADIdentifierQueryViewSectionsNumberOfQueryResults);
	
	NSArray *sections = reportingEnabled ?
	@[datasource, tables, links, groups, predicate, resultCount] :
	@[datasource, tables, links, groups, predicate];
	NSArray *rowCounts = reportingEnabled ?
	@[one, unknown, unknown, unknown, unknown, one] :
	@[one, unknown, unknown, unknown, unknown];
	
	NSArray *headers = reportingEnabled ?
	@[NSLocalizedString(MADTextQuerySetupDatasource, MADTextQuerySetupDatasource),
	  NSLocalizedString(MADTextQuerySelectTables, MADTextQuerySelectTables),
	  NSLocalizedString(MADTextQueryLinks, MADTextQueryLinks),
	  NSLocalizedString(MADTextQueryGroups, MADTextQueryGroups),
	  NSLocalizedString(MADTextQueryPredicate, MADTextQueryPredicate),
	  NSLocalizedString(MADTextQueryReportingMode, MADTextQueryReportingMode)] :
	@[NSLocalizedString(MADTextQuerySetupDatasource, MADTextQuerySetupDatasource),
	  NSLocalizedString(MADTextQuerySelectTables, MADTextQuerySelectTables),
	  NSLocalizedString(MADTextQueryLinks, MADTextQueryLinks),
	  NSLocalizedString(MADTextQueryGroups, MADTextQueryGroups),
	  NSLocalizedString(MADTextQueryPredicate, MADTextQueryPredicate)];
	
	NSNumber *height1 = @44.0;
	NSNumber *height2 = @([MADTableViewCellQueryTableName defaultHeight]);
	NSNumber *height3 = @([MADTableViewCellQueryLink defaultHeight]);
	NSArray *heights = reportingEnabled ?
	@[height1, height2, height3, height1, height1, height1] :
	@[height1, height2, height3, height1, height1];
	
	self.sections = sections;
	self.rowCountsBySection = [NSDictionary dictionaryWithObjects:rowCounts forKeys:sections];
	self.headersBySection = [NSDictionary dictionaryWithObjects:headers forKeys:sections];
	self.rowHeightsBySection = [NSDictionary dictionaryWithObjects:heights forKeys:sections];
}

@end
