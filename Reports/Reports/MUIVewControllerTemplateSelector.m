//
//  UIVIewControllerTemplateSelector.m
//  Reports
//
//  Created by Michael Thomason on 1/7/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MUIViewControllerTemplateSelector.h"

NSString * const MTSegueShowChooseDatasourceIdentifier = @"showChooseDatasource";

@interface MUIViewControllerTemplateSelector()

@property (nonatomic, retain) NSMutableArray *availableFilesCache;

@end

@implementation MUIViewControllerTemplateSelector

- (void)dealloc {
    [_availableFilesCache release];
    [_tableViewTemplates release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setTitle: NSLocalizedString(@"Templates", @"Templates")];
    }
    return self;    
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self setTitle: NSLocalizedString(@"Templates", @"Templates")];
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setAvailableFilesCache: [NSFileManager contentsOfTemplateDirectoryWithPathExtension:TEMPLATE_PATH_EXTENSION]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[self navigationItem] setPrompt: NSLocalizedString(@"Choose A Template", @"Choose A Template")];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:MTSegueShowChooseDatasourceIdentifier]) {
        [[segue destinationViewController] setDelegate:self];
    }
}

#pragma mark - Actions

- (IBAction)done:(id)sender {
    [[self delegate] viewControllerDidFinish:self];
}

- (IBAction)cancel:(id)sender {
    [[self delegate] viewControllerDidCancel:self];
}

- (void)viewControllerDidFinish:(id)sender {
    [[self delegate] viewControllerDidFinish:self];
}

- (void)viewControllerDidCancel:(id)sender {
    [[self delegate] viewControllerDidCancel:self];
}

#pragma mark - Table View Data Source Protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {    
    static NSString *MyIdentifier = @"UITableViewCellDocument";
    UITableViewCellDocument *result = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
    if (!result) {
        UINib *resultCellNib = [UINib nibWithNibName:@"UITableViewCellDocument" bundle:nil];
        [resultCellNib instantiateWithOwner:self options:nil];
        result = [self uITableViewCellDocument];
        [self setUITableViewCellDocument:nil];
    }
    
    [[result labelH1] setText:NSLocalizedString(@"Blank", @"The name of a blank template document.")];    
    [[result labelH2] setText:NSLocalizedString(@"A blank report template.", @"A subheading.")];

    return result;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
	
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSInteger numberOfRows;
    switch (section) {
        case 0: {
            numberOfRows = 1;
            break;
        }            
        default:
            numberOfRows = 0;
            break;
    }
	return numberOfRows;
}

#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSUInteger row = [indexPath row];
    if (row < [[self availableFilesCache] count]) {
        [[self templateSelectorDelegate] uIViewControllerTemplateSelectorRequestOpenOfTemplateAtUrl: [[self availableFilesCache] objectAtIndex: row]];
    }
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [UITableViewCellDocument defaultHeight];
}

@end