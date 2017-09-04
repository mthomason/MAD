//
//  MADConnectionSQLGenericViewController.h
//  MADAPI
//
//  Created by Michael on 9/4/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADAPI_MADConnectionSQLGenericViewController_h
#define MADAPI_MADConnectionSQLGenericViewController_h

#import <MADAPI/MADConnectionViewController.h>

@interface MADConnectionSQLGenericViewController : MADConnectionViewController

    @property (nonatomic, weak) IBOutlet UITextField *textFieldHost;
    @property (nonatomic, weak) IBOutlet UITextField *textFieldPort;
    @property (nonatomic, weak) IBOutlet UITextField *textFieldDatabase;

@end

#endif
