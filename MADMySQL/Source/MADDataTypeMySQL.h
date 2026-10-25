//
//  MADDataTypeMySQL.h
//  MAD
//
//  Created by Michael Thomason on 9/19/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADMySql_MADDataTypeMySQL_h
#define MADMySql_MADDataTypeMySQL_h

#import <Foundation/NSObject.h>

@interface MADDataTypeMySQL : NSObject

+ (short)dataTypeForNativeType:(NSInteger)nativeType;

@end

#endif
