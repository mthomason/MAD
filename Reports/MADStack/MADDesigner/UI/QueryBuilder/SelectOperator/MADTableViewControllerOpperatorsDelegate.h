//
//  MADTableViewControllerOpperatorsDelegate.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/1/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADTableViewControllerOpperatorsDelegate_h
#define MADTableViewControllerOpperatorsDelegate_h

#import <MAD/MADPredicateOperator.h>

@class MADTableViewControllerOpperators;

@protocol MADTableViewControllerOpperatorsDelegate
  @required
    - (void)uITableViewControllerOpperatorsDidSelectOperator:(MADPredicateOperator)operatorType;
  @optional
    - (void)uITableViewControllerOpperatorsDidFinish:(MADTableViewControllerOpperators *)controller;
@end

#endif /* MADTableViewControllerOpperatorsDelegate_h */
