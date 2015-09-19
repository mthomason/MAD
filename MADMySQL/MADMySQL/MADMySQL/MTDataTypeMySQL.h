//
//  MTDataTypeMySQL.h
//  MAD
//
//  Created by Michael Thomason on 9/19/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MADFoundation/MTDataType.h>

@interface MTDataTypeMySQL : NSObject

+ (MTDataType)dataTypeForNativeType:(NSInteger)nativeType;

@end
