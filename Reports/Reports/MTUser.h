//
//  MTUser.h
//  MAD
//
//  Created by Michael Thomason on 3/6/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTUser_h
#define Reports_MTUser_h

#import <Foundation/Foundation.h>

@interface MTUser : NSObject

- (NSArray *)hasMadDocuments;
- (BOOL)addDocument:(NSURL *)url error:(NSError **)error;

@end

#endif
