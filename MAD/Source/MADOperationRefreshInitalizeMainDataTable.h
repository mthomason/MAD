//
//  MADRefreshOperationInitializeMainDataTable.h
//  MAD Designer
//
//  Created by Michael Thomason on 4/2/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADRefreshOperationInitializeMainDataTable_h
#define Reports_MADRefreshOperationInitializeMainDataTable_h

#import <MADFoundation/MADOperation.h>

#import <MAD/MADDocumentDataProtocol.h>

@protocol MADOperationRefreshInitializeMainDataTableProtocol <NSObject>
	@property (readonly, nonatomic, weak) id <MADDocumentDataProtocol> document;
@end

@interface MADOperationRefreshInitializeMainDataTable : MADOperation
	<MADOperationRefreshInitializeMainDataTableProtocol>

	- (instancetype)initWithDocument:(id <MADDocumentDataProtocol>)document;

@end

#endif
