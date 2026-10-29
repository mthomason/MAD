//
//  MADPostgresConnectionViewController.h
//  MADPostgres
//
//  Created by Michael Thomason on 10/28/26.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADPostgresConnectionViewController_h
#define MADPostgresConnectionViewController_h

#include <TargetConditionals.h>

#if TARGET_OS_IPHONE
#import <MADAPI/MADConnectionSQLGenericViewController.h>

@interface MADPostgresConnectionViewController : MADConnectionSQLGenericViewController

@end
#endif

#endif /* MADPostgresConnectionViewController_h */
