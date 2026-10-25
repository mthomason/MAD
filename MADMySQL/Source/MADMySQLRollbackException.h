//
//  MADMySQLRollbackException.h
//  MADMySQL
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADMySQLRollbackException_h
#define MAD_MADMySQLRollbackException_h

#import "MADMySQLException.h"

/*
	Raised when a transaction rollback fails on the server.
 */
@interface MADMySQLRollbackException : MADMySQLException

@end

#endif
