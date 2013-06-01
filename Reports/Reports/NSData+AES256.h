//
//  NSData+AES256.h
//  Reports
//
//  Created by Michael Thomason on 5/31/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//
//  Found at http://pastie.org/426530#44
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCryptor.h>

@interface NSData (AES256)

- (NSData *)AES256EncryptWithKey:(NSString *)key;
- (NSData *)AES256DecryptWithKey:(NSString *)key;

@end
