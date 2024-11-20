//
//  NSData+AES256.h
//  Reports
//
//  Created by Michael Thomason on 5/31/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//
//  Found at http://pastie.org/426530#44
//

#ifndef Reports_NSData_AES256_h
#define Reports_NSData_AES256_h

#import <Foundation/NSData.h>
#import <CommonCrypto/CommonCryptor.h>

@interface NSData (AES256)

    - (NSData *)AES256EncryptWithKey:(NSString *)key;
    - (NSData *)AES256DecryptWithKey:(NSString *)key;

@end

#endif
