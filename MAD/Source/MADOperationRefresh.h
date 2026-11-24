//
//  MADOperationRefresh.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/15/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADRefreshOperation_h
#define Reports_MADRefreshOperation_h

#import <MADFoundation/MADOperation.h>

#import <MAD/MADDocumentDataProtocol.h>

@interface MADOperationRefresh : MADOperation

	- (instancetype)initWithDocument:(id <MADDocumentDataProtocol>)document;

@end

/// The refresh a composed document runs: resolves the explicit root, validates its
/// dependencies, refreshes each reachable source once serially with that source's
/// connection and dialect, composes the published inputs through MADComposer, and
/// publishes the completed root for normal consumers.  The ordinary document path is
/// MADOperationRefresh; a caller selects this one when the document has an explicit
/// root query.
@interface MADOperationRefreshComposed : MADOperation

	- (instancetype)initWithDocument:(id <MADDocumentDataProtocol>)document;

@end

#endif
