//
//  NSString+Encryption.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/16/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

/*  Example key
 static const unsigned char keyEncryption[] = {
 0x19, 0xdf, 0x8a, 0xc1, 0x0a, 0x25, 0x38, 0x57,
 0x06, 0x77, 0x6d, 0xd6, 0xbb, 0x5b, 0xd3, 0x21,
 0xdb, 0x46, 0xa5, 0xfd, 0x1e, 0xbe, 0x91, 0x69,
 0x8c, 0x0a, 0x18, 0x2b, 0xfb, 0x3f, 0x34, 0x06
 };*/

#ifndef MADDESIGNER_MADStringEncryption_h
#define MADDESIGNER_MADStringEncryption_h

#import <Foundation/NSString.h>

@class NSData;

@interface MADStringEncryption : NSObject

+ (NSData *)encryptString:(NSString *)string withKey:(unsigned char *)key keySize:(int)keySize;
+ (NSString *)decryptString:(NSData *)data withKey:(unsigned char *)key keySize:(int)keySize;

@end

#endif
