//
//  MADSectionsLayout.m
//  MAD
//
//  Created by Michael on 5/28/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADSectionsLayout.h"
#import <MAD/RptqStoreContext.h>
#import <Foundation/NSException.h>
#import <Foundation/NSExpression.h>
#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSPredicate.h>
#import <Foundation/NSBundle.h>
#import <MADAPI/MADDatabase.h>
#import "RptqDocumentSection.h"
#import "RptqDocumentSection+Extras.h"
#import "RptqQueryGroup.h"
#import "RptqQueryField.h"
#import "RptqQueryTable.h"
#import "RptqDatabaseSchemaField.h"
#import "MADSectionLayout.h"
#import "MADSectionGroupLayout.h"
#import "NSPredicate+Creators.h"

static inline NSUInteger groupHeaderIndex(NSUInteger);
static inline NSUInteger groupFooterIndex(NSUInteger, NSUInteger);

static inline NSUInteger groupHeaderIndex(NSUInteger sectionIndex) {
	return sectionIndex - 2;
}

static inline NSUInteger groupFooterIndex(NSUInteger sectionIndex, NSUInteger groupCount) {
	return (groupCount - 1) - (sectionIndex - groupCount - 3);
}

@interface MADSectionsLayout ()

@property (nonatomic, readwrite, strong) NSArray <NSSortDescriptor *> *groupSortDescriptors;

@end

@implementation MADSectionsLayout

- (instancetype)initWithManagedObjectContext:(RptqStoreContext *)managedObjectContext
                               databaseClass:(Class)databaseClass {
    if (self = [super init]) {
        NSArray <RptqDocumentSection *> *sections = (NSArray<RptqDocumentSection *> *)[managedObjectContext objectsForEntity:NSStringFromClass([RptqDocumentSection class])];
        NSMutableArray <NSDictionary *> *documentSections = [NSMutableArray arrayWithCapacity:sections.count];
        for (RptqDocumentSection *section in sections) {
            NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
            dictionary[NSStringFromSelector(@selector(identifier))] = @(section.identifier);
            dictionary[[RptqDocumentSection keyPathNumberOfRows]] = @(section.numberOfRows);
            dictionary[[RptqDocumentSection keyPathType]] = @(section.type);
            dictionary[[RptqDocumentSection keyPathVisibility]] = @(section.visibility);
            dictionary[[RptqDocumentSection keyPathWrappingStyle]] = @(section.wrappingStyle);
            dictionary[[RptqDocumentSection keyPathHeight]] = @(section.height);
            if (section.inReportReportHeader) dictionary[[RptqDocumentSection keyPathInReportHeader]] = section.inReportReportHeader;
            if (section.inReportReportFooter) dictionary[[RptqDocumentSection keyPathInReportFooter]] = section.inReportReportFooter;
            if (section.inReportPageHeader) dictionary[[RptqDocumentSection keyPathInPageHeader]] = section.inReportPageHeader;
            if (section.inReportPageFooter) dictionary[[RptqDocumentSection keyPathInPageFooter]] = section.inReportPageFooter;
            if (section.inReport) dictionary[[RptqDocumentSection keyPathInReport]] = section.inReport;
            if (section.inGroup) {
                dictionary[[RptqDocumentSection keyPathInGroup]] = section.inGroup;
                RptqQueryGroup *group = section.inGroup;
                RptqQueryField *field = group.hasField;
                dictionary[[RptqDocumentSection keyPathInGroupSort]] = @(group.sort);
                dictionary[[RptqDocumentSection keyPathInGroupWeight]] = @(group.weight);
                if (field) {
                    dictionary[[RptqDocumentSection keyPathInGroupHasFieldDatabaseSchemaFieldName]] = field.databaseSchemaField.name;
                    dictionary[[RptqDocumentSection keyPathInGroupHasFieldInQueryTableAlias]] = field.inQueryTable.alias;
                    dictionary[[RptqDocumentSection keyPathInGroupHasFieldInQueryTableDropIndex]] = @(field.inQueryTable.dropIndex);
                    dictionary[[RptqDocumentSection keyPathInGroupHasFieldDatabaseSchemaFieldDataType]] = @(field.databaseSchemaField.dataType);
                }
            }
            [documentSections addObject:dictionary];
        }

        NSString *keyPath = [RptqDocumentSection keyPathInReportHeader];
        
        NSPredicate *predicate;
        predicate = [NSPredicate newPredicateProperyNotNull:keyPath];
        
        NSArray <NSDictionary *> *reportHeaderArray = [documentSections filteredArrayUsingPredicate:predicate];
        if (reportHeaderArray.count > 0) {
            NSDictionary *reportHeaderDictionary = reportHeaderArray[0];
            _reportHeader = [[MADSectionLayout alloc] initWithObject: reportHeaderDictionary
                                                managedObjectContext: managedObjectContext];
        }
        
        // Report Footer
        keyPath = [RptqDocumentSection keyPathInReportFooter];
        predicate = [NSPredicate newPredicateProperyNotNull:keyPath];

        NSArray <NSDictionary *> *reportFooterArray = [documentSections filteredArrayUsingPredicate:predicate];
        if (reportFooterArray.count > 0) {
            NSDictionary *objects = reportFooterArray[0];
            _reportFooter = [[MADSectionLayout alloc] initWithObject: objects
                                                managedObjectContext: managedObjectContext];
        }
        
        // Page Header
        keyPath = [RptqDocumentSection keyPathInPageHeader];
        predicate = [NSPredicate newPredicateProperyNotNull:keyPath];
        
        NSArray <NSDictionary *> *pageHeaderArray = [documentSections filteredArrayUsingPredicate:predicate];
        if (pageHeaderArray.count > 0) {
            NSDictionary *objects = pageHeaderArray[0];
            _pageHeader = [[MADSectionLayout alloc] initWithObject: objects
                                              managedObjectContext: managedObjectContext];
        }

        // Page Footer
        keyPath = [RptqDocumentSection keyPathInPageFooter];
        predicate = [NSPredicate newPredicateProperyNotNull:keyPath];
        
        NSArray <NSDictionary *> *pageFooterArray = [documentSections filteredArrayUsingPredicate:predicate];
        if (pageFooterArray.count > 0) {
            NSDictionary *objects = pageFooterArray[0];
            _pageFooter = [[MADSectionLayout alloc] initWithObject: objects
                                              managedObjectContext: managedObjectContext];
        }

        // Detail
        keyPath = [RptqDocumentSection keyPathInReport];
        predicate = [NSPredicate newPredicateProperyNotNull:keyPath];

        NSArray <NSDictionary *> *detailArray = [documentSections filteredArrayUsingPredicate:predicate];
        if (detailArray.count > 0) {
            NSDictionary *objects = detailArray[0];
            _detail = [[MADSectionLayout alloc] initWithObject: objects
                                          managedObjectContext: managedObjectContext];
        }
        
        NSNumber *heightReportHeader = [[NSNumber alloc] initWithDouble: _reportHeader.displayHeight];
        NSNumber *heightReportFooter = [[NSNumber alloc] initWithDouble: _reportFooter.displayHeight];
        NSNumber *heightPageHeader = [[NSNumber alloc] initWithDouble: _pageHeader.displayHeight];
        NSNumber *heightPageFooter = [[NSNumber alloc] initWithDouble: _pageFooter.displayHeight];
        NSNumber *heightDetail = [[NSNumber alloc] initWithDouble: _detail.displayHeight];
        NSMutableDictionary <NSNumber *, NSNumber *> *heightForSectionID;
        heightForSectionID = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                                   heightReportHeader, _reportHeader.identifierObject,
                                                   heightReportFooter, _reportFooter.identifierObject,
                                                   heightPageHeader, _pageHeader.identifierObject,
                                                   heightPageFooter, _pageFooter.identifierObject,
                                                   heightDetail, _detail.identifierObject, nil];

        
        // Groups
        NSArray *groupHeaders = [[NSArray alloc] init];
        NSArray *groupFooters = [[NSArray alloc] init];
        
        keyPath = [RptqDocumentSection keyPathInGroup];
        predicate = [NSPredicate newPredicateProperyNotNull:keyPath];
        
        NSArray <NSDictionary *> *groupArray = [documentSections filteredArrayUsingPredicate:predicate];
        if (groupArray.count > 0) {
            MADSectionGroupLayout *groupLayout;
            NSNumber *heightObject;
            for (NSDictionary *objects in groupArray) {
                groupLayout = [[MADSectionGroupLayout alloc] initWithObject: objects
                                                       managedObjectContext: managedObjectContext
                               safeIdentifier:^NSString *(NSString *identifier) {
                                   if (databaseClass != NULL) {
                                       id dbClass = databaseClass;
                                       return [dbClass newSafeIdentifier:identifier];
                                   } else {
                                       return identifier;
                                   }
                               }];
                heightObject = [[NSNumber alloc] initWithDouble: groupLayout.displayHeight];
                [heightForSectionID setObject:heightObject forKey: groupLayout.identifierObject];
                switch (groupLayout.type) {
                    
                    case MADDocumentSectionTypeGroupHeader:
                        groupHeaders = [groupHeaders arrayByAddingObject: groupLayout];
                        break;
                    
                    case MADDocumentSectionTypeGroupFooter:
                        groupFooters = [groupFooters arrayByAddingObject: groupLayout];
                        break;
                        
                    default:
                        break;
                }
            }
        }
        
        NSString *keyWeight = NSStringFromSelector(@selector(weight));
        NSSortDescriptor *sortWeightAsc = [NSSortDescriptor sortDescriptorWithKey:keyWeight ascending:YES];
        NSArray *sortDescriptors = [[NSArray alloc] initWithObjects: sortWeightAsc, nil];
        self.groupHeaders = [groupHeaders sortedArrayUsingDescriptors: sortDescriptors];
        self.groupFooters = [groupFooters sortedArrayUsingDescriptors: sortDescriptors];
        self.heightForSectionID = heightForSectionID;

    }
    return self;
}

- (NSArray <NSSortDescriptor *> *)groupSortDescriptors {
    if (_groupSortDescriptors == nil) {
        NSSortDescriptor *sortDescriptor;
        NSEnumerator *groupHeaders = self.groupHeaders.objectEnumerator;
        NSMutableArray *groupSortDescriptors = [[NSMutableArray alloc] initWithCapacity: self.groupHeaders.count];
        for (MADSectionGroupLayout *groupSection in groupHeaders) {
            @autoreleasepool {
                sortDescriptor = [groupSection sortDescriptor];
                [groupSortDescriptors addObject: sortDescriptor];
            }
        }
        _groupSortDescriptors = groupSortDescriptors;
    }
    return _groupSortDescriptors;
}

- (NSUInteger)count {
    return self.groupHeaders.count * 2 + 5;
}

- (MADSectionLayout *)sectionLayoutAtIndex:(NSUInteger)index {
    switch ([RptqDocumentSection getSectionTypeforRow: index
                                   withNumberOfGroups: self.groupHeaders.count]) {
        case MADDocumentSectionTypeReportHeader:
            return self.reportHeader;
            break;
            
        case MADDocumentSectionTypePageHeader:
            return self.pageHeader;
            break;
            
        case MADDocumentSectionTypeBody:
            return self.detail;
            break;
            
        case MADDocumentSectionTypePageFooter:
            return self.pageFooter;
            break;
            
        case MADDocumentSectionTypeReportFooter:
            return self.reportFooter;
            break;
            
        case MADDocumentSectionTypeGroupHeader: {
            NSAssert(index - 2 < self.groupHeaders.count, @"Not enough headers.");
            return [self.groupHeaders objectAtIndex: groupHeaderIndex(index)];
            break;
        }
            
        case MADDocumentSectionTypeGroupFooter: {
            NSAssert(index - self.groupHeaders.count - 3 < self.groupFooters.count, @"Not enough footers.");
            return [self.groupFooters objectAtIndex: groupFooterIndex(index, self.groupHeaders.count)];
            break;
        }
            
        default:
            NSAssert(false, @"Unknown value at %s.", __PRETTY_FUNCTION__);
            return nil;
            break;
 
    }
}

- (NSString *)localizedDisplayNameAtIndex:(NSUInteger)index {
    return [[self class] localizedDisplayNameAtIndex:index groupCount:self.groupHeaders.count];
}

+ (NSString *)localizedDisplayNameAtIndex:(NSUInteger)index groupCount:(NSUInteger)groupCount {
    NSString *result = nil;
    switch ([RptqDocumentSection getSectionTypeforRow: index
                                   withNumberOfGroups: groupCount]) {
            
        case MADDocumentSectionTypeReportHeader:
            result = NSLocalizedString(@"Report Header", @"Report Header");
            break;
            
        case MADDocumentSectionTypePageHeader:
            result = NSLocalizedString(@"Page Header", @"Page Header");
            break;
            
        case MADDocumentSectionTypeBody:
            result = NSLocalizedString(@"Report Detail", @" Report Detail");
            break;
            
        case MADDocumentSectionTypePageFooter:
            result = NSLocalizedString(@"Page Footer", @"Page Footer");
            break;
            
        case MADDocumentSectionTypeReportFooter:
            result = NSLocalizedString(@"Report Footer", @"Report Footer");
            break;
            
        case MADDocumentSectionTypeGroupHeader:
			result = [NSString stringWithFormat:NSLocalizedString(@"Group Header (%lu)",
                                                                  @"\"Group Header 1\""), (unsigned long)groupHeaderIndex(index)];
            break;
            
        case MADDocumentSectionTypeGroupFooter:
			result = [NSString stringWithFormat:NSLocalizedString(@"Group Footer - (%lu)",
																  @"\"Group Footer 1\""), (unsigned long)groupFooterIndex(index, groupCount)];
            break;
            
        default:
            break;
            
    }
    return result;
}

@end
