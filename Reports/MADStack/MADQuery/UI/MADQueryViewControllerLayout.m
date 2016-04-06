//
//  MADQueryViewControllerLayout.m
//  MAD Designer
//
//  Created by Michael Thomason on 4/6/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADQueryViewControllerLayout.h"
#import "MADTableViewCellQueryTableName.h"

@interface MADQueryViewControllerLayout ()

    @property (nonatomic, readwrite, strong) NSArray *sections;
    @property (nonatomic, readwrite, strong) NSDictionary *headerSectionKeys;
    @property (nonatomic, readwrite, strong) NSDictionary *sectionRowKey;
    @property (nonatomic, readwrite, strong) NSDictionary *sectionRowHeightKey;

@end

@implementation MADQueryViewControllerLayout

- (instancetype)initWithNumberOfTables:(NSUInteger)numberOfTables reportingEnabled:(bool)reportingEnabled {
    if (self = [super init]) {
        
        NSString *h2 = NSLocalizedString(@"Setup Data Source", @"Setup Data Source");
        NSString *h3 = NSLocalizedString(@"Select Tables to Use", @"Select Tables to Use");
        NSString *h4 = NSLocalizedString(@"Link the Tables", @"Link the Tables");
        NSString *h5 = NSLocalizedString(@"Groups", @"Groups");
        NSString *h6 = NSLocalizedString(@"Predicate", @"Predicate");
        NSString *h7 = NSLocalizedString(@"Reporting Mode", @"Reporting Mode");

        NSNumber *one = @(1);
        NSNumber *unknown = @(-1);
        NSNumber *datasource = @(MTQuerySectionsDatasource);
        NSNumber *tables = @(MTQuerySectionsTables);
        NSNumber *resultCount = @(MTQuerySectionsNumberOfQueryResults);

        NSArray *sections = reportingEnabled ? @[datasource, tables, resultCount] :
        @[datasource, tables];
        NSArray *countRowsForSection = reportingEnabled ? @[one, unknown, one] : @[one, unknown];
        NSDictionary *countRowsForSectionDictionary =  [NSDictionary dictionaryWithObjects: countRowsForSection
                                                                                   forKeys: sections];
        
        NSArray *headersSection = reportingEnabled ? @[h2, h3, h7] : @[h2, h3];
        NSDictionary *headersSectionDictionary = [NSDictionary dictionaryWithObjects: headersSection forKeys: sections];
        NSNumber *height1 = @(50.0000f);
        NSNumber *height2 = @([MADTableViewCellQueryTableName defaultHeight]);
        NSArray *heightRowsForSection = reportingEnabled ? @[height1, height2, height1] : @[height1, height2];
        NSDictionary *heightRowsForSectionDictionaryDictionary = [NSDictionary dictionaryWithObjects: heightRowsForSection
                                                                                             forKeys: sections];
        
        switch (numberOfTables) {
            case 0:
                
                break;

            case 1:
                
                break;
            
            default:
                break;
        }
        
    }
    return self;
}

@end
