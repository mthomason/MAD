//
//  MADUnwindProtocol.h
//  MAD
//
//  Created by Michael Thomason on 8/21/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADUnwindProtocol_h
#define MAD_MADUnwindProtocol_h

@protocol MADUnwindProtocol <NSObject>
    @property (nonatomic, weak) UIViewController *unwindViewController;
@end

#endif
