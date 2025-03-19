//
//  MADRefreshOperationInitializeMainDataTable.h
//  MAD Designer
//
//  Created by Michael Thomason on 4/2/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MADRefreshOperationInitializeMainDataTable_h
#define Reports_MADRefreshOperationInitializeMainDataTable_h

#import <MADFoundation/MADOperation.h>

@class MADocument;

@protocol MADOperationRefreshInitializeMainDataTableProtocol <NSObject>
	@property (readonly, nonatomic, weak) MADocument *document;
@end

@interface MADOperationRefreshInitializeMainDataTable : MADOperation
	<MADOperationRefreshInitializeMainDataTableProtocol>

	- (instancetype)initWithDocument:(MADocument *)document;

@end

#endif
