//
//  MADQueryViewControllerLayout.m
//  MAD Designer
//
//  Created by Michael Thomason on 4/6/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADQueryViewControllerLayout.h"
#import "MADTableViewCellQueryTableName.h"
#import "MADTableViewCellQueryLink.h"

static NSString * const TextHeaderInformation   = @"Database Information";
static NSString * const TextHeaderTable         = @"Tables";
static NSString * const TextHeaderLink          = @"Joins";
static NSString * const TextHeaderGroups        = @"Grouped By";
static NSString * const TextHeaderPredicate     = @"Having Specified Criteria";
static NSString * const TextHeaderSettings      = @"Limit Query Result";

@interface MADQueryViewControllerLayoutSection ()
    @property (nonatomic, assign, readwrite) MTQuerySections querySection;
@end

@implementation MADQueryViewControllerLayoutSection

- (instancetype)initWithNumberOfTables:(NSUInteger)numberOfTables position:(short)position {
    if (self = [super init]) {
    
        switch (numberOfTables) {
            case 0:
                
                switch (position) {
                    case 0:
                        _querySection = MTQuerySectionsDatasource;
                        break;
                    case 1:
                        _querySection = MTQuerySectionsTables;
                        break;
                    case 2:
                        _querySection = MTQuerySectionsNumberOfQueryResults;
                        break;
                    default:
                        break;
                }
                
                break;

            case 1:
                
                switch (position) {
                    case 0:
                        _querySection = MTQuerySectionsDatasource;
                        break;
                    case 1:
                        _querySection = MTQuerySectionsTables;
                        break;
                    case 2:
                        _querySection = MTQuerySectionsGroups;
                        break;
                    case 3:
                        _querySection = MTQuerySectionsPredicate;
                        break;
                    case 4:
                        _querySection = MTQuerySectionsNumberOfQueryResults;
                        break;
                    default:
                        break;
                }
                
                break;

            default:
                
                switch (position) {
                    case 0:
                        _querySection = MTQuerySectionsDatasource;
                        break;
                    case 1:
                        _querySection = MTQuerySectionsTables;
                        break;
                    case 2:
                        _querySection = MTQuerySectionsLinks;
                        break;
                    case 3:
                        _querySection = MTQuerySectionsGroups;
                        break;
                    case 4:
                        _querySection = MTQuerySectionsPredicate;
                        break;
                    case 5:
                        _querySection = MTQuerySectionsNumberOfQueryResults;
                        break;
                    default:
                        break;
                }

        }
    
    }
    return self;
}

- (NSInteger)numberOfRows {
    return [MADQueryViewControllerLayoutSection numberOfRowsForSection:_querySection];
}

- (NSString *)name {
    return [MADQueryViewControllerLayoutSection nameForSection:_querySection];
}

- (CGFloat)height {
    return [MADQueryViewControllerLayoutSection heightForSection:_querySection];
}

- (SEL)selector {
    return [MADQueryViewControllerLayoutSection selectorForSection:_querySection];
}

+ (NSInteger)numberOfRowsForSection:(MTQuerySections)section {
    switch (section) {
            
        case MTQuerySectionsDatasource:
        case MTQuerySectionsSql:
        case MTQuerySectionsNumberOfQueryResults:
            return 1;
            break;
        case MTQuerySectionsDocumentGroups:
        case MTQuerySectionsTables:
        case MTQuerySectionsLinks:
        case MTQuerySectionsGroups:
        case MTQuerySectionsPredicate:
        default:
            return NSNotFound;
            break;
    }
}

+ (NSString *)nameForSection:(MTQuerySections)section {
    switch (section) {
        case MTQuerySectionsDocumentGroups:
            return NSLocalizedString(TextHeaderGroups, TextHeaderGroups);
            break;
        case MTQuerySectionsDatasource:
            return NSLocalizedString(TextHeaderInformation, TextHeaderInformation);
            break;
        case MTQuerySectionsTables:
            return NSLocalizedString(TextHeaderTable, TextHeaderTable);
            break;
        case MTQuerySectionsLinks:
            return NSLocalizedString(TextHeaderLink, TextHeaderLink);
            break;
        case MTQuerySectionsGroups:
            return NSLocalizedString(TextHeaderGroups, TextHeaderGroups);
            break;
        case MTQuerySectionsPredicate:
            return NSLocalizedString(TextHeaderPredicate, TextHeaderPredicate);
            break;
        case MTQuerySectionsSql:
            return NSLocalizedString(TextHeaderInformation, TextHeaderInformation);
            break;
        case MTQuerySectionsNumberOfQueryResults:
            return NSLocalizedString(TextHeaderSettings, TextHeaderSettings);
            break;
        default:
            return nil;
            break;
    }
}

+ (CGFloat)heightForSection:(MTQuerySections)section {
    switch (section) {
            
        case MTQuerySectionsTables:
            return [MADTableViewCellQueryTableName defaultHeight];
            break;
            
        case MTQuerySectionsLinks:
            return [MADTableViewCellQueryLink defaultHeight];
            break;
            
        case MTQuerySectionsDocumentGroups:
        case MTQuerySectionsDatasource:
        case MTQuerySectionsGroups:
        case MTQuerySectionsNumberOfQueryResults:
        case MTQuerySectionsPredicate:
        case MTQuerySectionsSql:
        default:
            return 44.0000f;
            break;
    }
}

+ (SEL)selectorForSection:(MTQuerySections)section {
    switch (section) {
        case MTQuerySectionsTables:
            return @selector(addTable:);
            break;
        case MTQuerySectionsLinks:
            return @selector(addLink:);
            break;
        case MTQuerySectionsGroups:
            return @selector(addGroup:);
            break;
        case MTQuerySectionsPredicate:
            return @selector(addPredicate:);
            break;
        default:
            return nil;
            break;
    }
}

@end

@interface MADQueryViewControllerLayout ()

    @property (nonatomic, readwrite, assign) short count;
    @property (nonatomic, readwrite, assign) NSUInteger numberOfTables;
    @property (nonatomic, readwrite, strong) NSArray <__kindof MADQueryViewControllerLayoutSection *> *sections;

@end

@implementation MADQueryViewControllerLayout

- (instancetype)initWithNumberOfTables:(NSUInteger)numberOfTables reportingEnabled:(BOOL)reportingEnabled {

    if (self = [super init]) {
        
        short count;
        switch (numberOfTables) {
            case 0:
                count = reportingEnabled ? 3 : 2;
                break;
            case 1:
                count = reportingEnabled ? 5 : 4;
                break;
            default:
                count = reportingEnabled ? 6 : 5;
                break;
        }
        
        _numberOfTables = numberOfTables;
        _count = count;
        
    }
    return self;
}

- (MTQuerySections)sectionAtIndex:(short)index {
    MADQueryViewControllerLayoutSection *layout = [[MADQueryViewControllerLayoutSection alloc] initWithNumberOfTables:_numberOfTables position:index];
    return layout.querySection;
}

- (NSIndexSet *)sectionTypesIndexs {
    NSMutableIndexSet *sectionTypes = [[NSMutableIndexSet alloc] init];
    NSArray <__kindof MADQueryViewControllerLayoutSection *> *sections = self.sections;
    for (MADQueryViewControllerLayoutSection *section in sections) {
        [sectionTypes addIndex:section.querySection];
    }
    return sectionTypes;
}

- (NSSet <__kindof NSNumber *> *)sectionTypes {
    NSMutableSet <__kindof NSNumber *> *sectionTypes = [[NSMutableSet alloc] initWithCapacity:(NSUInteger)_count];
    for (MADQueryViewControllerLayoutSection *section in self.sections) {
        @autoreleasepool {
            NSNumber *sectionType = [[NSNumber alloc] initWithShort:section.querySection];
            [sectionTypes addObject:sectionType];
        }
    }
    return sectionTypes;
}

- (MADQueryViewControllerLayoutSection *)layoutAtIndex:(short)index {
    return self.sections[(NSUInteger)index];
}

- (NSArray <__kindof MADQueryViewControllerLayoutSection *> *)sections {
    if (_sections != nil) {
        return _sections;
    } else {
        NSMutableArray <__kindof MADQueryViewControllerLayoutSection *> *sections = [[NSMutableArray alloc] initWithCapacity:(NSUInteger)_count];
        for (short i = 0; i < _count; i++) {
            @autoreleasepool {
                MADQueryViewControllerLayoutSection *section = [[MADQueryViewControllerLayoutSection alloc] initWithNumberOfTables:_numberOfTables position:i];
                [sections addObject:section];
            }
        }
        _sections = sections;
        return _sections;
    }
}

@end
