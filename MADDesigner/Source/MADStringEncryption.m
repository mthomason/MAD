//
//  NSString+Encryption.m
//  MAD Designer
//
//  Created by Michael Thomason on 5/16/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADStringEncryption.h"

#import <strings.h>

#import <openssl/crypto.h>
#import <openssl/aes.h>

#import <Foundation/NSData.h>

#import <openssl/evp.h>
#import <openssl/err.h>

@implementation MADStringEncryption

+ (NSData *)encryptString:(NSString *)s withKey:(unsigned char *)key keySize:(int)keySize {
	NSData *plainData = [s dataUsingEncoding:NSUTF8StringEncoding];
	if (!plainData || plainData.length == 0) return nil;
	
	if (keySize != 16 && keySize != 24 && keySize != 32) { // 128, 192, 256 bits
		return nil;
	}
	
	EVP_CIPHER_CTX *ctx = EVP_CIPHER_CTX_new();
	if (!ctx) return nil;
	
	const EVP_CIPHER *cipher = NULL;
	switch (keySize) {
		case 16: cipher = EVP_aes_128_ecb(); break;
		case 24: cipher = EVP_aes_192_ecb(); break;
		case 32: cipher = EVP_aes_256_ecb(); break;
		default:
			EVP_CIPHER_CTX_free(ctx);
			return nil;
	}
	
	if (1 != EVP_EncryptInit_ex(ctx, cipher, NULL, key, NULL)) {
		EVP_CIPHER_CTX_free(ctx);
		return nil;
	}
	
	int blockSize = EVP_CIPHER_CTX_block_size(ctx);
	if (blockSize <= 0) {
		EVP_CIPHER_CTX_free(ctx);
		return nil;
	}
	NSMutableData *cipherData = [NSMutableData dataWithLength:plainData.length + (unsigned int)blockSize];
	int outLen = 0;
	
	if (1 != EVP_EncryptUpdate(ctx, cipherData.mutableBytes, &outLen,
							   plainData.bytes, (int)plainData.length)) {
		EVP_CIPHER_CTX_free(ctx);
		return nil;
	}
	
	int finalLen = 0;
	if (1 != EVP_EncryptFinal_ex(ctx, cipherData.mutableBytes + outLen, &finalLen)) {
		EVP_CIPHER_CTX_free(ctx);
		return nil;
	}
	
	outLen += finalLen;
	EVP_CIPHER_CTX_free(ctx);
	
	cipherData.length = (unsigned int)outLen;
	return cipherData;
}

+ (NSString *)decryptString:(NSData *)data withKey:(unsigned char *)key keySize:(int)keySize {
	if (!data || data.length == 0) return @"";
	
	if (keySize != 16 && keySize != 24 && keySize != 32) {
		return @"";
	}
	
	EVP_CIPHER_CTX *ctx = EVP_CIPHER_CTX_new();
	if (!ctx) return @"";
	
	const EVP_CIPHER *cipher = NULL;
	switch (keySize) {
		case 16: cipher = EVP_aes_128_ecb(); break;
		case 24: cipher = EVP_aes_192_ecb(); break;
		case 32: cipher = EVP_aes_256_ecb(); break;
		default:
			EVP_CIPHER_CTX_free(ctx);
			return @"";
	}
	
	if (1 != EVP_DecryptInit_ex(ctx, cipher, NULL, key, NULL)) {
		EVP_CIPHER_CTX_free(ctx);
		return @"";
	}
	
	NSMutableData *plainData = [NSMutableData dataWithLength:data.length];
	int outLen = 0;
	
	if (1 != EVP_DecryptUpdate(ctx, plainData.mutableBytes, &outLen,
							   data.bytes, (int)data.length)) {
		EVP_CIPHER_CTX_free(ctx);
		return @"";
	}
	
	int finalLen = 0;
	if (1 != EVP_DecryptFinal_ex(ctx, plainData.mutableBytes + outLen, &finalLen)) {
		EVP_CIPHER_CTX_free(ctx);
		return @"";
	}
	
	outLen += finalLen;
	EVP_CIPHER_CTX_free(ctx);
	
	plainData.length = (unsigned int)outLen;
	return [[NSString alloc] initWithData:plainData encoding:NSUTF8StringEncoding] ?: @"";
}

@end
