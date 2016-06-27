//
//  MADReportSections.m
//  MAD
//
//  Created by Michael Thomason on 6/25/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADReportSections.h"
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSManagedObjectID.h>
#import "RptqDocument.h"
#import "RptqDocumentSectionEnumerator.h"
#import "RptqQuery+Extras.h"
#import "RptqDocumentSection+Extras.h"
#import "RptqQueryGroup.h"

#import "MADReportSectionEnumerator.h"

@interface MADReportSections ()

    @property (nonatomic, readwrite, weak)      id <MADReportSectionsDelegate> delegate;
    @property (nonatomic, readwrite, strong)    NSArray <MADReportSection *> *reportSections;

    @property (nonatomic, readwrite, weak)      RptqDocument *document;
    @property (nonatomic, readwrite, weak)      RptqQuery *mainQuery;

@end

static inline BOOL validateSelectedIndexWithGroupCount(NSUInteger selectedIndex, NSUInteger numberOfGroups);
static inline BOOL validateSelectedIndexWithGroupCount(NSUInteger selectedIndex, NSUInteger numberOfGroups) {
    return selectedIndex < (numberOfGroups * 2) + 5;
}

static inline NSUInteger queryGroupIndexForSelectedIndexOfTypeHeader(NSUInteger selectedIndex);
static inline NSUInteger queryGroupIndexForSelectedIndexOfTypeHeader(NSUInteger selectedIndex) {
    return selectedIndex - 2;
}

static inline NSUInteger queryGroupIndexForSelectedIndexOfTypeFooter(NSUInteger selectedIndex, NSUInteger numberOfGroups);
static inline NSUInteger queryGroupIndexForSelectedIndexOfTypeFooter(NSUInteger selectedIndex, NSUInteger numberOfGroups) {
    return ((2 + numberOfGroups) - (selectedIndex - (2 + numberOfGroups))) - 2;
}

@implementation MADReportSections

- (instancetype)initWithDelegate:(id <MADReportSectionsDelegate>) delegate {
    if (self = [super init]) {
        _delegate = delegate;
    }
    return self;
}

- (NSEnumerator *)sectionEnumerator {
    MADReportSectionEnumerator *sectionEnumerator = [[MADReportSectionEnumerator alloc] initWithQuery:[_delegate mainQuery]];
    return sectionEnumerator;
}

- (RptqDocument *)document {
    return _document ?: (_document = [_delegate documentSchema]);
}

- (RptqQuery *)mainQuery {
    return _mainQuery ?: (_mainQuery = [_delegate mainQuery]);
}

- (RptqDocumentSection *)documentSectionForSelectedIndex:(NSUInteger)selectedIndex
                                      withNumberOfGroups:(NSUInteger)numberOfGroups {
    
    RptqDocumentSection *resultSection = nil;
    
    if (validateSelectedIndexWithGroupCount(selectedIndex, numberOfGroups)) {
        
        switch ([RptqDocumentSection getSectionTypeforRow: selectedIndex
                                       withNumberOfGroups: numberOfGroups]) {
                
            case MADDocumentSectionTypeReportHeader:
                resultSection = self.document.hasReportHeaderSection;
                break;
                
            case MADDocumentSectionTypePageHeader:
                resultSection = self.document.hasPageHeaderSection;
                break;
                
            case MADDocumentSectionTypeBody:
                resultSection = self.document.hasDetailSection;
                break;
                
            case MADDocumentSectionTypePageFooter:
                resultSection = self.document.hasPageFooterSection;
                break;
                
            case MADDocumentSectionTypeReportFooter:
                resultSection = self.document.hasReportFooterSection;
                break;
                
            case MADDocumentSectionTypeGroupHeader: {
                RptqQueryGroup *group = [self.mainQuery queryGroupForIndex: queryGroupIndexForSelectedIndexOfTypeHeader(selectedIndex)];
                resultSection = [self headerSectionInSections:group.hasSection];
                break;
            }
                
            case MADDocumentSectionTypeGroupFooter: {
                RptqQueryGroup *group = [self.mainQuery queryGroupForIndex: queryGroupIndexForSelectedIndexOfTypeFooter(selectedIndex, numberOfGroups)];
                resultSection = [self footerSectionInSections:group.hasSection];
                break;
            }
                
            default:
                break;
        }
        
    }
    return resultSection;
}

- (RptqDocumentSection *)footerSectionInSections:(NSSet <RptqDocumentSection *> *)sections {
    for (RptqDocumentSection *section in sections) {
        if (section.type.integerValue == MADDocumentSectionTypeGroupFooter) {
            return section;
            break;
        }
    }
    return nil;
}

- (RptqDocumentSection *)headerSectionInSections:(NSSet <RptqDocumentSection *> *)sections {
    for (RptqDocumentSection *section in sections) {
        if (section.type.integerValue == MADDocumentSectionTypeGroupHeader) {
            return section;
            break;
        }
    }
    return nil;
}


@end
