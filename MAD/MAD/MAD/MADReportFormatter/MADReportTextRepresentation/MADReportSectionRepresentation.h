//
//  MADReportSectionRepresentation.h
//  MAD
//
//  Created by Michael Thomason on 10/29/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADReportSectionRepresentation_h
#define MAD_MADReportSectionRepresentation_h

#import <Foundation/NSObject.h>
#import <MAD/MADReportTextRepresentation.h>

typedef NS_ENUM(short, MNSDocumentSectionType) {
    MNSDocumentSectionTypeReportHeader = 1,
    MNSDocumentSectionTypeReportFooter = 2,
    MNSDocumentSectionTypePageHeader = 3,
    MNSDocumentSectionTypePageFooter = 4,
    MNSDocumentSectionTypeBody = 5,
    MNSDocumentSectionTypeGroupHeader = 6,
    MNSDocumentSectionTypeGroupFooter = 7,
};

@class MADReportSectionRowsRepresentation;

@interface MADReportSectionRepresentation : NSObject
    <MADTextRepresentationProtocol>

    @property (readonly) NSUInteger numberOfRows;
    @property (nonatomic, assign, getter=isVisibile) bool visibility;
    @property (nonatomic, assign)                       MNSDocumentSectionType type;
    @property (nonatomic, assign) NSUInteger groupLevel;

    - (nonnull instancetype)initWithNumberOfRows:(NSUInteger)capacity NS_DESIGNATED_INITIALIZER;
    - (void)addRow:(nonnull MADReportSectionRowsRepresentation *)row;

@end

#endif
