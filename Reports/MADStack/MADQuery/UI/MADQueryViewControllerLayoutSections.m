//
//  MADQueryViewControllerLayoutSections.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/24/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADQueryViewControllerLayoutSections.h"
#import <CoreGraphics/CGBase.h>
#import "MADTableViewCellQueryTableName.h"
#import "MADTableViewCellQueryLink.h"
#import "MADQueryViewControllerLayoutSectionSelectorProtocol.h"

static NSString * const TextHeaderInformation   = @"Database Information";
static NSString * const TextHeaderTable         = @"Tables";
static NSString * const TextHeaderLink          = @"Joins";
static NSString * const TextHeaderGroups        = @"Grouped By";
static NSString * const TextHeaderPredicate     = @"Having Specified Criteria";
static NSString * const TextHeaderSettings      = @"Limit Query Result";

@interface MADQueryViewControllerLayoutSection ()
    @property (nonatomic, assign, readwrite) MADQueryViewControllerSections querySection;
@end

@implementation MADQueryViewControllerLayoutSection

- (instancetype)initWithNumberOfTables:(NSUInteger)numberOfTables position:(short)position {
    if (self = [super init]) {
    
        switch (numberOfTables) {
            case 0:
                
                switch (position) {
                    case 0:
                        _querySection = MADQueryViewControllerSectionsDatasource;
                        break;
                    case 1:
                        _querySection = MADQueryViewControllerSectionsTables;
                        break;
                    case 2:
                        _querySection = MADQueryViewControllerSectionsNumberOfQueryResults;
                        break;
                    default:
                        break;
                }
                
                break;

            case 1:
                
                switch (position) {
                    case 0:
                        _querySection = MADQueryViewControllerSectionsDatasource;
                        break;
                    case 1:
                        _querySection = MADQueryViewControllerSectionsTables;
                        break;
                    case 2:
                        _querySection = MADQueryViewControllerSectionsGroups;
                        break;
                    case 3:
                        _querySection = MADQueryViewControllerSectionsPredicate;
                        break;
                    case 4:
                        _querySection = MADQueryViewControllerSectionsNumberOfQueryResults;
                        break;
                    default:
                        break;
                }
                
                break;

            default:
                
                switch (position) {
                    case 0:
                        _querySection = MADQueryViewControllerSectionsDatasource;
                        break;
                    case 1:
                        _querySection = MADQueryViewControllerSectionsTables;
                        break;
                    case 2:
                        _querySection = MADQueryViewControllerSectionsLinks;
                        break;
                    case 3:
                        _querySection = MADQueryViewControllerSectionsGroups;
                        break;
                    case 4:
                        _querySection = MADQueryViewControllerSectionsPredicate;
                        break;
                    case 5:
                        _querySection = MADQueryViewControllerSectionsNumberOfQueryResults;
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

+ (NSInteger)numberOfRowsForSection:(MADQueryViewControllerSections)section {
    switch (section) {
            
        case MADQueryViewControllerSectionsDatasource:
        case MADQueryViewControllerSectionsSql:
        case MADQueryViewControllerSectionsNumberOfQueryResults:
            return 1;
            break;
        case MADQueryViewControllerSectionsDocumentGroups:
        case MADQueryViewControllerSectionsTables:
        case MADQueryViewControllerSectionsLinks:
        case MADQueryViewControllerSectionsGroups:
        case MADQueryViewControllerSectionsPredicate:
        default:
            return NSNotFound;
            break;
    }
}

+ (NSString *)nameForSection:(MADQueryViewControllerSections)section {
    switch (section) {
        case MADQueryViewControllerSectionsDocumentGroups:
            return NSLocalizedString(TextHeaderGroups, TextHeaderGroups);
            break;
        case MADQueryViewControllerSectionsDatasource:
            return NSLocalizedString(TextHeaderInformation, TextHeaderInformation);
            break;
        case MADQueryViewControllerSectionsTables:
            return NSLocalizedString(TextHeaderTable, TextHeaderTable);
            break;
        case MADQueryViewControllerSectionsLinks:
            return NSLocalizedString(TextHeaderLink, TextHeaderLink);
            break;
        case MADQueryViewControllerSectionsGroups:
            return NSLocalizedString(TextHeaderGroups, TextHeaderGroups);
            break;
        case MADQueryViewControllerSectionsPredicate:
            return NSLocalizedString(TextHeaderPredicate, TextHeaderPredicate);
            break;
        case MADQueryViewControllerSectionsSql:
            return NSLocalizedString(TextHeaderInformation, TextHeaderInformation);
            break;
        case MADQueryViewControllerSectionsNumberOfQueryResults:
            return NSLocalizedString(TextHeaderSettings, TextHeaderSettings);
            break;
        default:
            return nil;
            break;
    }
}

+ (CGFloat)heightForSection:(MADQueryViewControllerSections)section {
    switch (section) {
            
        case MADQueryViewControllerSectionsTables:
            return [MADTableViewCellQueryTableName defaultHeight];
            break;
            
        case MADQueryViewControllerSectionsLinks:
            return [MADTableViewCellQueryLink defaultHeight];
            break;
            
        case MADQueryViewControllerSectionsDocumentGroups:
        case MADQueryViewControllerSectionsDatasource:
        case MADQueryViewControllerSectionsGroups:
        case MADQueryViewControllerSectionsNumberOfQueryResults:
        case MADQueryViewControllerSectionsPredicate:
        case MADQueryViewControllerSectionsSql:
        default:
            return 44.0000f;
            break;
    }
}

+ (SEL)selectorForSection:(MADQueryViewControllerSections)section {
    switch (section) {
        case MADQueryViewControllerSectionsTables:
            return @selector(addTable:);
            break;
        case MADQueryViewControllerSectionsLinks:
            return @selector(addLink:);
            break;
        case MADQueryViewControllerSectionsGroups:
            return @selector(addGroup:);
            break;
        case MADQueryViewControllerSectionsPredicate:
            return @selector(addPredicate:);
            break;
        default:
            return nil;
            break;
    }
}

@end
