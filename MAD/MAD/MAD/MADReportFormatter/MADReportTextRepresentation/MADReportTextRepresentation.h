//
//  MADReportTextRepresentation.h
//  MAD Designer
//
//  Created by Michael Thomason on 10/25/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADReportTextRepresentation_h
#define MAD_MADReportTextRepresentation_h

#import <Foundation/NSObject.h>
#import "MADDocumentTextRepresentationProtocol.h"

@class MADReportPageRepresentation;

@interface MADReportTextRepresentation : NSObject
    <MADTextRepresentationProtocol>

    @property (readonly) NSUInteger numberOfPages;

    - (instancetype)initWithPageCount:(NSUInteger)capacity NS_DESIGNATED_INITIALIZER;

    - (MADReportPageRepresentation *)pageIndex:(NSUInteger)pageIndex;
    - (void)setPage:(MADReportPageRepresentation *)page forPageIndex:(NSUInteger)pageIndex;

    - (void)removeAllPages;

@end

#endif
