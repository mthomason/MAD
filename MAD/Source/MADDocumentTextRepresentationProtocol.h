//
//  MADDocumentTextRepresentationProtocol.h
//  MAD
//
//  Created by Michael Thomason on 5/23/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADDocumentTextRepresentationProtocol_h
#define MAD_MADDocumentTextRepresentationProtocol_h

@protocol MADTextRepresentationProtocol <NSObject>

	@property (nonatomic, assign) NSUInteger elementOffset;
	@property (nonatomic, assign) NSUInteger characterOffset;
	- (NSUInteger)elementCount;
	- (NSUInteger)characterCount;

@end

#endif /* MADDocumentTextRepresentationProtocol_h */
