//
//  MADAlignment_t.h
//  MAD
//
//  Created by Michael on 2/16/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADAlignment_t_h
#define MADAlignment_t_h

#import <MAD/MADHorizontalAlignmentType.h>
#import <MAD/MADVerticalAlignmentType.h>

struct MADAlignment_t {
    MADHorizontalAlignment horizontal;
    MADVerticalAlignment vertical;
};
typedef struct MADAlignment_t MADAlignment_t;

#endif /* MADAlignment_t_h */
