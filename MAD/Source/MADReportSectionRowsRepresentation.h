//
//  MADReportSectionRowsRepresentation.h
//  MAD
//
//  Created by Michael Thomason on 10/30/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADReportSectionRowsRepresentation_h
#define MAD_MADReportSectionRowsRepresentation_h

#import <Foundation/NSObject.h>
#import <MAD/MADDocumentTextRepresentationProtocol.h>

@class MADReportLineRepresentation;

@interface MADReportSectionRowsRepresentation : NSObject
	<MADTextRepresentationProtocol>

	@property (nonatomic, readonly) NSUInteger itemCount;

	- (nonnull instancetype)initWithNumberOfSectionRowElements:(NSUInteger)elementCount NS_DESIGNATED_INITIALIZER;
	- (NSArray <__kindof MADReportLineRepresentation *>  * _Nonnull)allLines;
	- (void)addLine:(nonnull MADReportLineRepresentation *)line;

@end

#endif
