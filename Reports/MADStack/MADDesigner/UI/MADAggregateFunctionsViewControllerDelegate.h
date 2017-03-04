//
//  MADAggregateFunctionsViewControllerDelegate.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/1/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADAggregateFunctionsViewControllerDelegate_h
#define MAD_MADAggregateFunctionsViewControllerDelegate_h

#import <MAD/MADAggregateFunctionType.h>

@protocol MADAggregateFunctionsViewControllerDelegate
    - (void)didSelectFunction:(MTAggregateFunctionType)functionType;
@end

#endif /* MADAggregateFunctionsViewControllerDelegate_h */
