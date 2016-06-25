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
    @property (nonatomic, assign, readwrite) MADIdentifierQueryViewSections querySection;
@end

@implementation MADQueryViewControllerLayoutSection

- (instancetype)initWithNumberOfTables:(NSUInteger)numberOfTables position:(short)position {
    if (self = [super init]) {
    
        switch (numberOfTables) {
            case 0:
                
                switch (position) {
                    case 0:
                        _querySection = MADIdentifierQueryViewSectionsDatasource;
                        break;
                    case 1:
                        _querySection = MADIdentifierQueryViewSectionsTables;
                        break;
                    case 2:
                        _querySection = MADIdentifierQueryViewSectionsNumberOfQueryResults;
                        break;
                    default:
                        break;
                }
                
                break;

            case 1:
                
                switch (position) {
                    case 0:
                        _querySection = MADIdentifierQueryViewSectionsDatasource;
                        break;
                    case 1:
                        _querySection = MADIdentifierQueryViewSectionsTables;
                        break;
                    case 2:
                        _querySection = MADIdentifierQueryViewSectionsGroups;
                        break;
                    case 3:
                        _querySection = MADIdentifierQueryViewSectionsPredicate;
                        break;
                    case 4:
                        _querySection = MADIdentifierQueryViewSectionsNumberOfQueryResults;
                        break;
                    default:
                        break;
                }
                
                break;

            default:
                
                switch (position) {
                    case 0:
                        _querySection = MADIdentifierQueryViewSectionsDatasource;
                        break;
                    case 1:
                        _querySection = MADIdentifierQueryViewSectionsTables;
                        break;
                    case 2:
                        _querySection = MADIdentifierQueryViewSectionsLinks;
                        break;
                    case 3:
                        _querySection = MADIdentifierQueryViewSectionsGroups;
                        break;
                    case 4:
                        _querySection = MADIdentifierQueryViewSectionsPredicate;
                        break;
                    case 5:
                        _querySection = MADIdentifierQueryViewSectionsNumberOfQueryResults;
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

+ (NSInteger)numberOfRowsForSection:(MADIdentifierQueryViewSections)section {
    switch (section) {
            
        case MADIdentifierQueryViewSectionsDatasource:
        case MADIdentifierQueryViewSectionsSql:
        case MADIdentifierQueryViewSectionsNumberOfQueryResults:
            return 1;
            break;
        case MADIdentifierQueryViewSectionsDocumentGroups:
        case MADIdentifierQueryViewSectionsTables:
        case MADIdentifierQueryViewSectionsLinks:
        case MADIdentifierQueryViewSectionsGroups:
        case MADIdentifierQueryViewSectionsPredicate:
        default:
            return NSNotFound;
            break;
    }
}

+ (NSString *)nameForSection:(MADIdentifierQueryViewSections)section {
    switch (section) {
        case MADIdentifierQueryViewSectionsDocumentGroups:
            return NSLocalizedString(TextHeaderGroups, TextHeaderGroups);
            break;
        case MADIdentifierQueryViewSectionsDatasource:
            return NSLocalizedString(TextHeaderInformation, TextHeaderInformation);
            break;
        case MADIdentifierQueryViewSectionsTables:
            return NSLocalizedString(TextHeaderTable, TextHeaderTable);
            break;
        case MADIdentifierQueryViewSectionsLinks:
            return NSLocalizedString(TextHeaderLink, TextHeaderLink);
            break;
        case MADIdentifierQueryViewSectionsGroups:
            return NSLocalizedString(TextHeaderGroups, TextHeaderGroups);
            break;
        case MADIdentifierQueryViewSectionsPredicate:
            return NSLocalizedString(TextHeaderPredicate, TextHeaderPredicate);
            break;
        case MADIdentifierQueryViewSectionsSql:
            return NSLocalizedString(TextHeaderInformation, TextHeaderInformation);
            break;
        case MADIdentifierQueryViewSectionsNumberOfQueryResults:
            return NSLocalizedString(TextHeaderSettings, TextHeaderSettings);
            break;
        default:
            return nil;
            break;
    }
}

+ (CGFloat)heightForSection:(MADIdentifierQueryViewSections)section {
    switch (section) {
            
        case MADIdentifierQueryViewSectionsTables:
            return [MADTableViewCellQueryTableName defaultHeight];
            break;
            
        case MADIdentifierQueryViewSectionsLinks:
            return [MADTableViewCellQueryLink defaultHeight];
            break;
            
        case MADIdentifierQueryViewSectionsDocumentGroups:
        case MADIdentifierQueryViewSectionsDatasource:
        case MADIdentifierQueryViewSectionsGroups:
        case MADIdentifierQueryViewSectionsNumberOfQueryResults:
        case MADIdentifierQueryViewSectionsPredicate:
        case MADIdentifierQueryViewSectionsSql:
        default:
            return 44.0000f;
            break;
    }
}

+ (SEL)selectorForSection:(MADIdentifierQueryViewSections)section {
    switch (section) {
        case MADIdentifierQueryViewSectionsTables:
            return @selector(addTable:);
            break;
        case MADIdentifierQueryViewSectionsLinks:
            return @selector(addLink:);
            break;
        case MADIdentifierQueryViewSectionsGroups:
            return @selector(addGroup:);
            break;
        case MADIdentifierQueryViewSectionsPredicate:
            return @selector(addPredicate:);
            break;
        default:
            return nil;
            break;
    }
}

@end
