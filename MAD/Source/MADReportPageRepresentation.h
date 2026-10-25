//
//  MADReportPageRepresentation.h
//  MAD Designer
//
//  Created by Michael Thomason on 10/25/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADReportPageRepresentation_h
#define MAD_MADReportPageRepresentation_h

#import <Foundation/NSObject.h>
#import <MAD/MADDocumentTextRepresentationProtocol.h>

@class MADReportSectionRepresentation;

@interface MADReportPageRepresentation : NSObject
	<MADTextRepresentationProtocol>

	@property (readonly) NSUInteger numberOfSections;

	- (nonnull instancetype)initWithNumberOfSections:(NSUInteger)numberOfSections NS_DESIGNATED_INITIALIZER;
	- (void)addSection:(nonnull MADReportSectionRepresentation *)section;

	/// The sections in page order: what a reader of the representation walks, and what
	/// the json-report member serializes (MADReportExporterJSONReport.h).
	- (nonnull NSArray <__kindof MADReportSectionRepresentation *> *)allSections;

@end

#endif
