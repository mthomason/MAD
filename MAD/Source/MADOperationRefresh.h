//
//  MADOperationRefresh.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/15/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MADRefreshOperation_h
#define Reports_MADRefreshOperation_h

#import <MADFoundation/MADOperation.h>

#import <MAD/MADDocumentDataProtocol.h>

@interface MADOperationRefresh : MADOperation

	- (instancetype)initWithDocument:(id <MADDocumentDataProtocol>)document;

@end

#endif
