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

	/// YES when the document carries an explicit composition root and must refresh
	/// through MADOperationRefreshComposed rather than the ordinary single-query
	/// chain.  The CLI and the native application both use this to pick the
	/// coordinator, so the decision lives in one place.
	+ (BOOL)documentUsesComposedRefresh:(id <MADDocumentDataProtocol>)document;

@end

/// The refresh a composed document runs: resolves the explicit root, validates its
/// dependencies, walks the whole graph topologically (children before parents, root
/// last, each node once), compiles every composing node as a general query against
/// its attached children, and publishes the completed root for normal consumers.
/// The ordinary document path is MADOperationRefresh; a caller selects this one when
/// the document has an explicit root query.
@interface MADOperationRefreshComposed : MADOperation

	- (instancetype)initWithDocument:(id <MADDocumentDataProtocol>)document;

	/// The names of the nodes in the order they executed — children before parents,
	/// root last, each once.  Populated after a refresh succeeds or fails partway; a
	/// diagnostic of the walk, and what the tests assert the order and once-only
	/// invariants against.
	@property (nonatomic, readonly, copy) NSArray<NSString *> *executedNodeNames;

@end

#endif
