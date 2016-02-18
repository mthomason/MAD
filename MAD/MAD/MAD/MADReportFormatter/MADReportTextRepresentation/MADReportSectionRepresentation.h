//
//  MADReportSectionRepresentation.h
//  MAD
//
//  Created by Michael Thomason on 10/29/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MAD/MADDocumentSectionType.h>
#import "MADTextRepresentationProtocol.h"

@class MADReportSectionRowsRepresentation;

@interface MADReportSectionRepresentation : NSObject
    <MADTextRepresentationProtocol>

    @property (readonly) NSUInteger numberOfRows;
    @property (nonatomic, assign, getter=isVisibile) bool visibility;
    @property (nonatomic, assign) MNSDocumentSectionType type;

    - (nonnull instancetype)initWithNumberOfRows:(NSUInteger)capacity NS_DESIGNATED_INITIALIZER;
    - (void)addRow:(nonnull MADReportSectionRowsRepresentation *)row;

@end
