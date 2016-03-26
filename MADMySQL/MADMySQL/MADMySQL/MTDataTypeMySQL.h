//
//  MTDataTypeMySQL.h
//  MAD
//
//  Created by Michael Thomason on 9/19/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MADMySql_MADDataTypeMySQL_h
#define MADMySql_MADDataTypeMySQL_h

#import <Foundation/NSObject.h>
#import <MADFoundation/MADDataType.h>

@interface MTDataTypeMySQL : NSObject

    + (MTDataType)dataTypeForNativeType:(NSInteger)nativeType;

@end

#endif
