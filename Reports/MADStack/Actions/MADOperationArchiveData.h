//
//  MADOperationArchiveData.h
//  MAD Designer
//
//  Created by Michael Thomason on 9/11/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MADOperationArchiveData : NSOperation

- (instancetype)initWithURL:(NSURL *)url andObject:(id <NSCoding>)object;

@end
