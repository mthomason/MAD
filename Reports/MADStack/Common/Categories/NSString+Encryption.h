//
//  NSString+Encryption.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/16/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Encryption)

+ (NSData *)encryptString:(NSString *)string withKey:(unsigned char *)key keySize:(int)keySize;
+ (NSString *)decryptString:(NSData *)data withKey:(unsigned char *)key keySize:(int)keySize;

@end
