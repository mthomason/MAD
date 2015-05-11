//
//  MTUnwindProtocol.h
//  MAD
//
//  Created by Michael Thomason on 8/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MTUnwindProtocol_h
#define MAD_MTUnwindProtocol_h

@protocol MTUnwindProtocol <NSObject>

    @property (nonatomic, weak) UIViewController *unwindViewController;

@end

#endif
