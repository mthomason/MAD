//
//  MADPostgresConnection.h
//  MADPostgres
//
//  Created by Michael Thomason on 10/28/26.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADPostgresConnection_h
#define MADPostgresConnection_h

#import <Foundation/Foundation.h>
#import <MADPostgres/libpq-fe.h>

NS_ASSUME_NONNULL_BEGIN

@interface MADPostgresConnection : NSObject

@property (nonatomic, readonly, nullable) PGconn *pgConn;
@property (nonatomic, readonly, getter=isConnected) BOOL connected;
@property (nonatomic, readonly, copy, nullable) NSString *errorMessage;

- (BOOL)connectWithHost:(NSString *)host
				   port:(int32_t)port
				   user:(NSString *)user
			   password:(nullable NSString *)password
			   database:(NSString *)database
				  error:(NSError *_Nullable __autoreleasing *_Nullable)error;

- (void)disconnect;

- (nullable NSString *)escapeLiteral:(nullable NSString *)literal;
- (nullable NSString *)escapeIdentifier:(nullable NSString *)identifier;

@end

NS_ASSUME_NONNULL_END

#endif /* MADPostgresConnection_h */
