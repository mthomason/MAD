//
//  MADDataTypePostgres.h
//  MADPostgres
//
//  Created by Michael Thomason on 10/28/26.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADDataTypePostgres_h
#define MADDataTypePostgres_h

#import <Foundation/Foundation.h>
#import <MADFoundation/MADDataType.h>
#import <MADPostgres/pg_type_d.h>

NS_ASSUME_NONNULL_BEGIN

@interface MADDataTypePostgres : NSObject

+ (MADDataType)madDataTypeFromPostgresOID:(unsigned int)oid;
+ (MADDataType)madDataTypeFromPostgresTypeName:(nullable NSString *)typeName;
+ (NSNumber *)madDataTypeNumberFromPostgresOID:(unsigned int)oid;
+ (NSNumber *)madDataTypeNumberFromPostgresTypeName:(nullable NSString *)typeName;

@end

NS_ASSUME_NONNULL_END

#endif /* MADDataTypePostgres_h */
