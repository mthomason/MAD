//
//  MADViewControllerBase.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/6/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//
//
//  MADViewController Base Class
//
//  !!!:    Allow this code to be included multiple times, as it abstracts UIViewController,
//  !!!:        UITableViewController, UICollectionViewController, etc...
//

@property (nonatomic, assign, readonly) BOOL firstTimeViewDidAppear;
@property (nonatomic, assign, readonly) BOOL firstTimeViewWillAppear;

@property (nonatomic, assign, readonly) BOOL firstTimeViewWillLayoutSubviews;

<<<<<<< HEAD
@property (nullable, nonatomic, readonly, strong) MADTabBarController *tabBarController;
=======
@property(nullable, nonatomic, readonly, strong) MADTabBarController *tabBarController;
>>>>>>> 0a2323e5616d276b13219302a96949345893ed16
