//
//  MADMySQLCommitException.h
//  MADMySQL
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADMySQLCommitException_h
#define MAD_MADMySQLCommitException_h

#import "MADMySQLException.h"

/*
	Raised when a transaction commit fails on the server.
 */
@interface MADMySQLCommitException : MADMySQLException

@end

#endif
