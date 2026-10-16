//
//  MADOperationRefreshInitialize.h
//  MAD Designer
//
//  Created by Michael Thomason on 4/2/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MADRefreshOperationInitialize_h
#define Reports_MADRefreshOperationInitialize_h

#import <MADFoundation/MADOperation.h>

#import <MAD/MADDocumentDataProtocol.h>

@protocol MADRefreshOperationInitializeProtocol <NSObject>
	@property (readonly) id <MADDocumentDataProtocol> document;
@end

@interface MADOperationRefreshInitialize : MADOperation

	- (instancetype)initWithDocument:(id <MADDocumentDataProtocol>)document;

@end

#endif
