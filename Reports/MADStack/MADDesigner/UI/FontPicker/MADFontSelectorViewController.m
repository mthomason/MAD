//
//  UITableViewControllerFontSelector.m
//  Reports
//
//  Created by Michael Thomason on 1/6/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADFontSelectorViewController.h"
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MAD/MADFont.h>
#import <MAD/MADFonts.h>

@interface MADFontSelectorViewController()

@property (nonatomic, strong) NSString *familyName;
@property (nonatomic, strong) MADFonts *madFonts;

@end

@implementation MADFontSelectorViewController

- (instancetype)initWithStyle:(UITableViewStyle)style {
    if (self = [super initWithStyle:style]) {
        [self initalize];
    }
    return self;
}

-  (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self initalize];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self initalize];
    }
    return self;
}

- (void)initalize {
    MADFonts *fonts = [[MADFonts alloc] init];
    self.madFonts = fonts;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.navigationController.navigationBar.barTintColor = [MADColorEverydayApps newColorRed];
    self.navigationController.navigationBar.alpha = 1.0000f;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden: NO animated: animated];
    if (self.clearsBackground) {
        self.tableView.backgroundView = nil;
    }

}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    self.navigationController.parentViewController.preferredContentSize = CGSizeMake(320.0000f, 680.0000f);

    self.navigationController.navigationBar.frame = CGRectMake(self.navigationController.navigationBar.frame.origin.x, self.topLayoutGuide.length - self.navigationController.navigationBar.frame.size.height, self.navigationController.navigationBar.frame.size.width, self.navigationController.navigationBar.frame.size.height);
    self.tableView.contentInset = UIEdgeInsetsMake(self.topLayoutGuide.length, CGSizeZero.width, self.bottomLayoutGuide.length, CGSizeZero.width);
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(self.topLayoutGuide.length, CGSizeZero.width, self.bottomLayoutGuide.length, CGSizeZero.width);
    if (self.firstTimeViewWillLayoutSubviews) {
        self.tableView.contentOffset = CGPointMake(CGPointZero.x, CGPointZero.y - self.topLayoutGuide.length);
    }

}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

#pragma mark -
#pragma mark Table view datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.madFonts.familyNames.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reusableCellWithIdentifier = @"MADFontSelectorDefaultCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reusableCellWithIdentifier forIndexPath:indexPath];
    
    if (cell) {
        NSString *familyName = self.madFonts.familyNames[indexPath.row];
        cell.textLabel.text = familyName;
        cell.textLabel.font = [UIFont fontWithName: familyName
                                              size: cell.textLabel.font.pointSize];
        cell.accessoryType = [self.familyName isEqualToString:familyName] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = [UIColor clearColor];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    for (UITableViewCell *visibleCell in tableView.visibleCells) {
        visibleCell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    [tableView deselectRowAtIndexPath:indexPath animated:YES];


    NSString *familyName = self.madFonts.familyNames[indexPath.row];
    [self.delegate uITableViewControllerDidUpdateFontToFontWithName:familyName];
}

- (void)setSelectedFamilyName:(NSString *)name {
    NSString *familyName = [NSString stringWithString:name];
    self.familyName = familyName;
}

@end
