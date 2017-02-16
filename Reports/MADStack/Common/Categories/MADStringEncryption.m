//
//  NSString+Encryption.m
//  MAD Designer
//
//  Created by Michael Thomason on 5/16/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADStringEncryption.h"

#import <strings.h>

#import <openssl/crypto.h>
#import <openssl/aes.h>

#import <Foundation/NSData.h>

@implementation MADStringEncryption

+ (NSData *)encryptString:(NSString *)s withKey:(unsigned char *)key keySize:(int)keySize {
    const unsigned char *org = (const unsigned char *)[s cStringUsingEncoding:NSUTF8StringEncoding];
    AES_KEY key_enc;
    unsigned char *part_encrypted = malloc(sizeof(unsigned char) * strlen((const char *)org));
    AES_set_encrypt_key(key, keySize, &key_enc);
    AES_encrypt(org, part_encrypted, &key_enc);
    return [NSData dataWithBytes:part_encrypted length:strlen((const char *)part_encrypted)];
}

+ (NSString *)decryptString:(NSData *)data withKey:(unsigned char *)key keySize:(int)keySize {
    
    AES_KEY key_dec;
    unsigned char *dec_out = malloc(sizeof(unsigned char) * data.length);
    
    AES_set_decrypt_key(key, keySize, &key_dec);
    AES_decrypt(data.bytes, dec_out, &key_dec);
    
    return strlen((char *)dec_out) ? [NSString stringWithCString:(char *)dec_out
                                                        encoding:NSUTF8StringEncoding] : @"";
}

@end
