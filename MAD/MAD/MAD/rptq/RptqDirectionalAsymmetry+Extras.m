//
//  RptqDirectionalAsymmetry+Extras.m
//  MAD
//
//  Created by Michael on 5/15/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqDirectionalAsymmetry+Extras.h"
#import "RptqDirectionalProperty+Extras.h"

@implementation RptqDirectionalAsymmetry (Extras)

+ (NSString *)keyTop {
    return [RptqDirectionalProperty keyTop];
}

+ (NSString *)keyBottom {
    return [RptqDirectionalProperty keyBottom];
}

+ (NSString *)keyLeft {
    return [RptqDirectionalProperty keyLeft];
}

+ (NSString *)keyRight {
    return [RptqDirectionalProperty keyLeft];
}

@end
