//
//  MTDocumentObjectNewStaticLabelViewController.m
//  Reports
//
//  Created by Michael Thomason on 3/17/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTDocumentObjectNewStaticLabelViewController.h"

NSString * const MTDocumentObjectNewStaticLabelViewControllerIdentifier = @"MTDocumentObjectNewStaticLabelViewControllerIdentifier";

@interface MTDocumentObjectNewStaticLabelViewController ()

@property (nonatomic, retain) IBOutlet UILabel *labelTextLabel;
@property (nonatomic, retain) IBOutlet UITextField *labelTextTextbox;

@end

@implementation MTDocumentObjectNewStaticLabelViewController

- (void)dealloc {
    [_labelTextLabel release];
    [_labelTextTextbox release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (NSString *)userInputedText {
    return [[self labelTextTextbox] text];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
