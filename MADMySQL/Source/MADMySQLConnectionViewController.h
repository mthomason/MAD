//
//  MADConnectionViewController.h
//  Reports
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADMySQL_MADConnectionViewController_h
#define MADMySQL_MADConnectionViewController_h

#include <TargetConditionals.h>

#if TARGET_OS_IPHONE
#import <MADAPI/MADConnectionSQLGenericViewController.h>

@interface MADMySQLConnectionViewController : MADConnectionSQLGenericViewController

@end
#endif

#endif
