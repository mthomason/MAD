//
//  MADDatabaseResultsProtocol.h
//  MAD
//
//  Created by Michael on 8/28/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADDatabaseResultsProtocol_h
#define MADDatabaseResultsProtocol_h

#import <Foundation/NSObject.h>

@class MADCredential, MADDataTable, NSString, MADQuery;

NS_ASSUME_NONNULL_BEGIN

@protocol MADDatabaseResultsProtocol <NSObject>
@required
@optional
- (MADCredential *)getCredentialsForKey:(NSString *)key;
- (MADDataTable *)dataTableForQuery:(MADQuery *)query;
- (void)getCredentialsForKey:(NSString *)key
				  completion:(void (^)(MADCredential * _Nullable credential, NSError * _Nullable error))completion;
@end

NS_ASSUME_NONNULL_END

#endif /* MADDatabaseResultsProtocol_h */
