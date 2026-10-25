//
//  MADReportSectionRepresentation.h
//  MAD
//
//  Created by Michael Thomason on 10/29/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADReportSectionRepresentation_h
#define MAD_MADReportSectionRepresentation_h

#import <Foundation/NSObject.h>
#import <MAD/MADDocumentTextRepresentationProtocol.h>
#import <MAD/MADocumentSectionType.h>

@class MADReportSectionRowsRepresentation;

@interface MADReportSectionRepresentation : NSObject
	<MADTextRepresentationProtocol>

	@property (readonly) NSUInteger numberOfRows;
	@property (nonatomic, assign, getter=isVisibile) BOOL visibility;
	@property (nonatomic, assign) MADDocumentSectionType type;
	/// Which query grouping the section belongs to; 0 for the report's own sections.
	@property (nonatomic, assign) NSUInteger groupLevel;

	- (nonnull instancetype)initWithNumberOfRows:(NSUInteger)capacity NS_DESIGNATED_INITIALIZER;
	- (bool)addRow:(nonnull MADReportSectionRowsRepresentation *)row
			 error:(NSError * __nullable __autoreleasing * __nullable)error;

	/// The rows in order: what a reader of the representation walks, and what the
	/// json-report member serializes (MADReportExporterJSONReport.h).
	- (nonnull NSArray <__kindof MADReportSectionRowsRepresentation *> *)allRows;

@end

#endif
