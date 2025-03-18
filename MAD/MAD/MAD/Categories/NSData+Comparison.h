//
//  NSData+Comparison.h
//  MAD
//
//  Created by Michael Thomason on 6/12/14.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#ifndef Reports_NSData_Comparison_h
#define Reports_NSData_Comparison_h

#import <Foundation/Foundation.h>

@interface NSData (Comparison)

- (NSComparisonResult)compareData:(NSData *)data;

@end

#endif
