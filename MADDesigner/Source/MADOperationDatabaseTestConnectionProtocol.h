//
//  MADOperationDatabaseTestConnectionProtocol.h
//  MAD Designer
//
//  Created by Michael on 8/12/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADOperationDatabaseTestConnectionProtocol_h
#define MADOperationDatabaseTestConnectionProtocol_h

@protocol MADOperationDatabaseTestConnectionProtocol <NSObject>

	@property (nonatomic, readonly, strong) NSError *error;
	@property (nonatomic, readonly, assign) BOOL success;

@end

#endif /* MADOperationDatabaseTestConnectionProtocol_h */
