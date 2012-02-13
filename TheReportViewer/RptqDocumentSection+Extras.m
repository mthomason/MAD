//
//  RptqDocumentSection+Extras.m
//  TheReportViewer
//
//  Created by Michael Thomason on 2/12/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentSection+Extras.h"
#import "RptqDocument+Extras.h"
#import "RptqDocument.h"
#import "RptqQueryGroup.h"
#import "RptqQuery.h"

@implementation RptqDocumentSection (Extras)

+ (MNSSectionType)getSectionTypeforRow:(NSInteger)row withNumberOfGroups:(NSInteger)numberOfGroups {
    NSInteger documentHeader    = 0;
    NSInteger pageHeader        = 1;
    NSInteger body              = 2 + numberOfGroups;       //6
    NSInteger pageFooter        = 3 + (2 * numberOfGroups); //11
    NSInteger documentFooter    = 4 + (2 * numberOfGroups); //12
    MNSSectionType result;

    if (row == documentHeader) {
        result = MNSSectionTypeReportHeader;
    } else if (row == pageHeader) {
        result = MNSSectionTypePageHeader;
    } else if (row == body) {
        result = MNSSectionTypeBody;
    } else if (row == pageFooter) {
        result = MNSSectionTypePageFooter;
    } else if (row == documentFooter) {
        result = MNSSectionTypeReportFooter;
    } else {
        NSInteger locationRelitaveToGroup = row - pageHeader;
        BOOL isGroupHeader = locationRelitaveToGroup <= numberOfGroups;
        if (isGroupHeader) {
            result = MNSSectionTypeGroupHeader;
        } else {
            result = MNSSectionTypeGroupFooter;
        }
    }
    
    return result;
}

+ (RptqDocumentSection *)getDocumentSectionForRow:(NSInteger)row
                               withNumberOfGroups:(NSInteger)numberOfGroups
                          andManagedObjectContext:(NSManagedObjectContext *)objectContext {
    
    RptqDocument *document = [[RptqDocument getMainDocumentForManagedObjectContext:objectContext] retain];
    
    RptqDocumentSection *resultSection = nil;
    
    switch ([RptqDocumentSection getSectionTypeforRow:row withNumberOfGroups:numberOfGroups]) {
        case MNSSectionTypeReportHeader:
            resultSection = [[[document hasReportHeaderSection] retain] autorelease];
            break;
        case MNSSectionTypePageHeader:
            resultSection = [[[document hasPageHeaderSection] retain] autorelease];
            break;
        case MNSSectionTypeBody:
            resultSection = [[[document hasDetailSection] retain] autorelease];
            break;
        case MNSSectionTypePageFooter:
            resultSection = [[[document hasPageFooterSection] retain] autorelease];
            break;
        case MNSSectionTypeReportFooter:
            resultSection = [[[document hasReportFooterSection] retain] autorelease];
            break;
        case (MNSSectionTypeGroupHeader): {
            NSInteger groupNumber = row - 2;
            NSSet *groupsUnsorted = [[document hasQuery] hasQueryGroups];
            for (RptqQueryGroup *group in groupsUnsorted) {
                if ([[group weight] integerValue] == groupNumber) {
                    NSSet *sections = [[group hasSection] retain];
                    for (RptqDocumentSection *section in sections) {
                        if ([[section type] integerValue] == MNSSectionTypeGroupHeader) {
                                resultSection = [[section retain] autorelease];
                            break;
                        }
                    }                    
                    [sections release];
                    break;
                }
            }
            break;
        }
        case MNSSectionTypeGroupFooter: {
            NSInteger body              = 2 + numberOfGroups;
            NSInteger indentLevel = body - (row - body);
            NSInteger groupNumber = indentLevel - 1;
            NSSet *groupsUnsorted = [[document hasQuery] hasQueryGroups];
            for (RptqQueryGroup *group in groupsUnsorted) {
                if ([[group weight] integerValue] == groupNumber) {
                    NSSet *sections = [[group hasSection] retain];
                    for (RptqDocumentSection *section in sections) {
                        if ([[section type] integerValue] == MNSSectionTypeGroupFooter) {
                            resultSection = [[section retain] autorelease];
                            break;
                        }
                    }                    
                    [sections release];
                    break;
                }
            }
            break;
        }
        default:

            break;
    }
    
    [document autorelease];
    return resultSection;
}

+ (NSString *)getDocumentSectionNameForRow:(NSInteger)row withNumberOfGroups:(NSInteger)numberOfGroups {
    NSInteger documentHeader    = 0;
    NSInteger pageHeader        = 1;
    NSInteger body              = 2 + numberOfGroups;       //6
    NSInteger pageFooter        = 3 + (2 * numberOfGroups); //11
    NSInteger documentFooter    = 4 + (2 * numberOfGroups); //12
    NSString *groupText = nil;
    if (row == documentHeader) {
        groupText = NSLocalizedString(@"Report Header", @"Report Header");
    } else if (row == pageHeader) {
        groupText = NSLocalizedString(@"Page Header", @"Page Header");
    } else if (row == body) {
        groupText = NSLocalizedString(@"Report Detail", @" Report Detail");
    } else if (row == pageFooter) {
        groupText = NSLocalizedString(@"Page Footer", @"Page Footer");
    } else if (row == documentFooter) {
        groupText = NSLocalizedString(@"Report Footer", @"Report Footer");
    } else {
        NSInteger locationRelitaveToGroup = row - pageHeader;
        BOOL isGroupHeader = locationRelitaveToGroup <= numberOfGroups;
        NSInteger indentLevel = (row <= body) ? row : body - (row - body);
        if (isGroupHeader) {
            groupText = [NSString stringWithFormat:NSLocalizedString(@"Group Header %d", @""), indentLevel - 1];
        } else {
            groupText = [NSString stringWithFormat:NSLocalizedString(@"Group Footer %d", @""), indentLevel - 1];
        }
    }
    return groupText;
}

+ (NSInteger)getDocumentSectionIndentLevelForRow:(NSInteger)row withNumberOfGroups:(NSInteger)numberOfGroups {
    NSInteger body = 2 + numberOfGroups;
    return (row <= body) ? row : body - (row - body);
}

@end