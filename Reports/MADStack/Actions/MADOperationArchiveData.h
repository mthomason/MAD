//
//  MADOperationArchiveData.h
//  MAD Designer
//
//  Created by Michael Thomason on 9/11/15.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADOperationArchiveData_h
#define MAD_Designer_MADOperationArchiveData_h

#import <MADFoundation/MADOperation.h>

@interface MADOperationArchiveData : MADOperation

    - (instancetype)initWithURL:(NSURL *)url andObject:(id <NSCoding>)object;

@end

#endif
