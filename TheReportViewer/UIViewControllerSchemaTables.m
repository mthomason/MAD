//
//  CoreDataTableViewController.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UIViewControllerSchemaTables.h"
#import "UIViewControllerSchemaAddTable.h"
#import "UIViewControllerSchemaAddLink.h"
#import "Constants.h"

typedef enum {
	UIViewControllerSchemaTablesSectionsInstructions = 0,
	UIViewControllerSchemaTablesSectionsTables = 1,
	UIViewControllerSchemaTablesSectionsLinks = 2,
    UIViewControllerSchemaTablesSectionsSql = 3
} UIViewControllerSchemaTablesSections;

@interface UIViewControllerSchemaTables() {
@private
    NSArray *tableSectionTitles;
}

@property (retain) NSArray *tableSectionTitles;

@end

@implementation UIViewControllerSchemaTables

@synthesize tableSectionTitles;

@synthesize tableMetaData = _tableMetaData;

@synthesize delegate = _delegate;
@synthesize tableViewQueryBuilder;

@synthesize uITableViewCellInstruction;
@synthesize uITableViewCellTableName;
@synthesize uITableViewCellQueryLink;
@synthesize uITableViewCellOverride;
@synthesize uITableViewCellQueryInput;

@synthesize managedDocumentQuery = _managedDocumentQuery;

@synthesize uIViewControllerAddTable = _uIViewControllerAddTable, uIViewControllerAddLink = _uIViewControllerAddLink;

@synthesize uIViewControllerBuildQuery = _uIViewControllerBuildQuery, uIViewControllerTables = _uIViewControllerTables, uIViewControllerLinks = _uIViewControllerLinks, uIViewControllerQuery = _uIViewControllerQuery;


- (void)dealloc {
    [_managedDocumentQuery release];
    [_uIViewControllerAddTable release];
    [_uIViewControllerAddLink release];
    [_tableMetaData release];
    [tableViewQueryBuilder release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
                
        //Initalize the add table and add links views (could be lazy loaded).

        //Initalize the header views
        UIStoryboard *sb = [[UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil] retain];
        UIViewController *vc = [[sb instantiateViewControllerWithIdentifier:@"UIViewControllerTableHeaderBuildQuery"] retain];
        [self setUIViewControllerBuildQuery: vc];
        [vc release];
        vc = [[sb instantiateViewControllerWithIdentifier:@"UIViewControllerTableHeaderTables"] retain];
        for (id subview in [[vc view] subviews]) {
            if ([subview isKindOfClass: [UIButton class]]) {
                UIButton *button = (UIButton *)subview;
                if (button) {
                    [button addTarget:self action:@selector(addTable:) forControlEvents:UIControlEventTouchUpInside];
                }
            }
        }
        [self setUIViewControllerTables: vc];
        [vc release];
        vc = [[sb instantiateViewControllerWithIdentifier:@"UIViewControllerTableHeaderLinks"] retain];
        for (id subview in [[vc view] subviews]) {
            if ([subview isKindOfClass: [UIButton class]]) {
                UIButton *button = (UIButton *)subview;
                if (button) {
                    [button addTarget:self action:@selector(addLink:) forControlEvents:UIControlEventTouchUpInside];
                }
            }
        }
        [self setUIViewControllerLinks: vc];
        [vc release];
        vc = [[sb instantiateViewControllerWithIdentifier:@"UIViewControllerTableHeaderQuery"] retain];
        [self setUIViewControllerQuery: vc];
        [vc release];
        [sb release];
        
        
        //These files define common attributes of the mostly static table.
        NSArray *sections = [[NSArray alloc] initWithObjects:
                             [NSNumber numberWithInt:UIViewControllerSchemaTablesSectionsInstructions],
                             [NSNumber numberWithInt:UIViewControllerSchemaTablesSectionsTables],
                             [NSNumber numberWithInt:UIViewControllerSchemaTablesSectionsLinks],
                             [NSNumber numberWithInt:UIViewControllerSchemaTablesSectionsSql], nil];
        
        NSArray *countRowsForSection = [[NSArray alloc] initWithObjects:
                                        [NSNumber numberWithInt: 1],
                                        [NSNumber numberWithInt: -1],
                                        [NSNumber numberWithInt: -1],
                                        [NSNumber numberWithInt: 2], nil];
        NSDictionary *countRowsForSectionDictionary = [[NSDictionary alloc] initWithObjects: countRowsForSection
                                                                                    forKeys: sections];
        [countRowsForSection release];
        
        NSArray *headersSection = [[NSArray alloc] initWithObjects: @"Build Query", @"Tables", @"Links", @"SQL", nil];
        NSDictionary *headersSectionDictionary = [[NSDictionary alloc] initWithObjects: headersSection
                                                                               forKeys: sections];
        [headersSection release];
        
        NSArray *heightRowsForSection = [[NSArray alloc] initWithObjects:
                                         [NSNumber numberWithFloat: [UITableViewCellInstruction defaultHeight]],
                                         [NSNumber numberWithFloat: [UITableViewCellTableName defaultHeight]],
                                         [NSNumber numberWithFloat: [UITableViewCellQueryLink defaultHeight]],
                                         [NSNumber numberWithFloat: [UITableViewCellQueryInput defaultHeight]], nil];
        NSDictionary *heightRowsForSectionDictionaryDictionary = [[NSDictionary alloc] initWithObjects: heightRowsForSection
                                                                                               forKeys: sections];
        [heightRowsForSection release];
        
        NSDictionary *tableOutline = [[NSDictionary alloc] initWithObjectsAndKeys:
                                      headersSectionDictionary, KEY_TBL_SEC_HEADERS,
                                      countRowsForSectionDictionary, KEY_TBL_SEC_ROW_COUNT,
                                      heightRowsForSectionDictionaryDictionary, KEY_TBL_SEC_ROW_HEIGHT, nil];
        
        
        [self setTableMetaData: tableOutline];
        
        [tableOutline release];
        [heightRowsForSectionDictionaryDictionary release];
        [headersSectionDictionary release];
        [countRowsForSectionDictionary release];
        [sections release];
        
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload {
    [self setTableViewQueryBuilder:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear: animated];
    //[[self tableViewQueryBuilder] reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {

}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showAddTableViewController"]) {
        if ([[segue destinationViewController] isKindOfClass: [UINavigationController class]]) {
            UINavigationController *navControl = [[segue destinationViewController] retain];
            if ([navControl topViewController]) {
                if ([[navControl topViewController] isKindOfClass:[UIViewControllerSchemaAddTable class]]) {
                    
                    UIViewControllerSchemaAddTable *tvc = (UIViewControllerSchemaAddTable *)[navControl topViewController];
                    [tvc setManagedDocumentQuery: [self managedDocumentQuery]];
                    if (tvc) {
                        [tvc setDelegate:self];
                    }
                    
                    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Table"];
                    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
                    request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
                    //request.predicate = [NSPredicate predicateWithFormat:@"name like %@", @"%"];
                    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest: request
                                                                                          managedObjectContext: [[self managedDocumentQuery] managedObjectContext]
                                                                                            sectionNameKeyPath: nil
                                                                                                     cacheName: nil];
                    [tvc setFetchedResultsController: frc];
                    [frc release];

                }
            }
            
            [navControl release];
        }

        [[segue destinationViewController] setDelegate:self];
    } else if ([[segue identifier] isEqualToString:@"showAddLinkViewController"]) {
        [[segue destinationViewController] setDelegate:self];
    }
}

#pragma mark - Actions

- (IBAction)done:(id)sender {
    [[self delegate] uIViewControllerSchemaTablesDelegateDidFinish: self];
}

- (void)addTable:(id)sender {
    [self performSegueWithIdentifier: @"showAddTableViewController" sender: sender];
}

- (void)addLink:(id)sender {
    [self performSegueWithIdentifier: @"showAddLinkViewController" sender: sender];
}

#pragma mark - Model Delegates

- (void)viewControllerSchemaAddLinkDidFinish:(UIViewControllerSchemaAddLink *)controller {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)viewControllerSchemaAddTableDidFinish:(UIViewControllerSchemaAddTable *)controller {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)viewControllerSchemaAddTableDidSelectTable:(Table *)controller {
    [self dismissModalViewControllerAnimated:YES];
    //FIXME: Do something here.
}

#pragma mark -
#pragma mark Table View Data Source Protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [[[self tableMetaData] objectForKey: KEY_TBL_SEC_HEADERS] count];
}

/*
 - (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
 
 }
 */

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = [indexPath row];
    NSInteger section = [indexPath section];
    
    UITableViewCell *result = nil;
    
    switch (section) {
        case UIViewControllerSchemaTablesSectionsInstructions: {
            static NSString *MyIdentifierUITableViewCellInstruction = @"UITableViewCellInstruction";
            //UITableViewCellInstruction *result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellInstruction];
            result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellInstruction];
            if (!result) {
                UINib *resultCellNib = [UINib nibWithNibName:@"UITableViewCellInstruction" bundle:nil];
                [resultCellNib instantiateWithOwner:self options:nil];
                result = [self uITableViewCellInstruction];
                [self setUITableViewCellInstruction:nil];
            }
            break;
        }
        case UIViewControllerSchemaTablesSectionsTables: {
            static NSString *MyIdentifierUITableViewCellTableName = @"UITableViewCellTableName";
            //UITableViewCellTableName *result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellTableName];
            result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellTableName];
            if (!result) {
                UINib *resultCellNib = [UINib nibWithNibName:@"UITableViewCellTableName" bundle:nil];
                [resultCellNib instantiateWithOwner:self options:nil];
                result = [self uITableViewCellTableName];
                [self setUITableViewCellTableName:nil];
            }
            break;
        }
        case UIViewControllerSchemaTablesSectionsLinks: {
            static NSString *MyIdentifierUITableViewCellInstruction = @"UITableViewCellQueryLink";
            //UITableViewCellQueryLink *result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellInstruction];
            result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellInstruction];
            if (!result) {
                UINib *resultCellNib = [UINib nibWithNibName:@"UITableViewCellQueryLink" bundle:nil];
                [resultCellNib instantiateWithOwner:self options:nil];
                result = [self uITableViewCellQueryLink];
                [self setUITableViewCellQueryLink:nil];
            }
            break;
        }
        case UIViewControllerSchemaTablesSectionsSql: {
            switch (row) {
                case 0: {
                    static NSString *MyIdentifierUITableViewCellOverride = @"UITableViewCellOverride";
                    //UITableViewCellOverride *result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellOverride];
                    result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellOverride];
                    if (!result) {
                        UINib *resultCellNib = [UINib nibWithNibName:@"UITableViewCellOverride" bundle:nil];
                        [resultCellNib instantiateWithOwner:self options:nil];
                        result = [self uITableViewCellOverride];
                        [self setUITableViewCellOverride:nil];
                    }
                    break;
                }
                default: {
                    static NSString *MyIdentifierUITableViewCellQueryInput = @"UITableViewCellQueryInput";
                    //UITableViewCellQueryInput *result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellQueryInput];
                    result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellQueryInput];
                    if (!result) {
                        UINib *resultCellNib = [UINib nibWithNibName:@"UITableViewCellQueryInput" bundle:nil];
                        [resultCellNib instantiateWithOwner:self options:nil];
                        result = [self uITableViewCellQueryInput];
                        [self setUITableViewCellQueryInput:nil];
                    }
                    break;
                }
            }
            break;
        }
        default: {
            break;
        }
    }
    
    if (!result) {
        result = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DefaultCellShouldNotGetHere"] autorelease];
        [[result textLabel] setText: @"Err"];
    }
    
    return result;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
	
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
    // = [[rowsDict objectForKey:[NSNumber numberWithInteger: section - 1]] integerValue];

    NSDictionary *rowsDict = [[self tableMetaData] objectForKey: KEY_TBL_SEC_ROW_COUNT];
    NSInteger numberOfRows = 0;
    
    [rowsDict objectForKey: [NSNumber numberWithInt: section]];
    
    NSLog(@"rowsDict: %@", rowsDict);
    
    numberOfRows = [[rowsDict objectForKey:[NSNumber numberWithInt: section]] intValue];

    
/*
    [[self tableMetaData] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSLog(@"{%@, %@} of type {%@, %@}.", key, obj, NSStringFromClass([key class]), NSStringFromClass([obj class]));
        
        if ([key isEqualToString: KEY_TBL_SEC_ROW_COUNT]) {
            (NSDictionary *)obj ;
            //NSDictionary *rowsForSectionDictionary = [[NSDictionary alloc] initWithDictionary: obj];
            //[rowsForSectionDictionary release];
            *stop = YES;
        }
        
    }];*/

    if (numberOfRows < 0) {
        switch (section) {
            case UIViewControllerSchemaTablesSectionsTables: {
                numberOfRows = 0;   //FIXME: NUMBER Tables Count
                break;
            }
            case UIViewControllerSchemaTablesSectionsLinks: {
                numberOfRows = 0;   //FIXME: NUMBER Tables Count
                break;
            }
            default:
                numberOfRows = 0;
                break;
        }
    }
	return numberOfRows;
}

/*
 - (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
 
 }
 */

/*
 - (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
 
 }
 */

/*
 - (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
 NSString *result;
 switch (section) {
 case 0:
 result = @"";
 break;
 case 1:
 result = @"";
 break;
 default:
 result = @"";
 break;
 }
 return result;
 }
 */

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *results = nil;
    switch (section) {
        case UIViewControllerSchemaTablesSectionsInstructions:
            results = [[[[self uIViewControllerBuildQuery] view] retain] autorelease];
            break;
        case UIViewControllerSchemaTablesSectionsTables:
            results = [[[[self uIViewControllerTables] view] retain] autorelease];
            break;
        case UIViewControllerSchemaTablesSectionsLinks:
            results = [[[[self uIViewControllerLinks] view] retain] autorelease];
            break;
        case UIViewControllerSchemaTablesSectionsSql:
            results = [[[[self uIViewControllerQuery] view] retain] autorelease];
            break;
        default:
            break;
    }
    return results;
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

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 29.0000f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat result = UITABLEVIEWCELL_HEIGHT_DEFAULT;
    NSInteger section = [indexPath section];
    if (section == UIViewControllerSchemaTablesSectionsSql) {
        result = [indexPath row] == 0 ? [UITableViewCellOverride defaultHeight] : [UITableViewCellQueryInput defaultHeight];
    } else {
        NSDictionary *tableMetaHeight = [[self tableMetaData] objectForKey:KEY_TBL_SEC_ROW_HEIGHT];
        if (tableMetaHeight) result = [[tableMetaHeight objectForKey: [NSNumber numberWithInt: section]] floatValue];
    }
    return result;
}


/*
 - (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath { }
 */

/*
 - (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section { }
 */

/*
 
 - (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 */

/*
 - (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 */

/*
 - (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
 
 }
 */

/*
 - (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 */

/*
 - (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
 
 }
 */


/*
 - (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 */

/*
 - (NSIndexPath *)tableView:(UITableView *)tableView willDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 */

/*
 - (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 */

/*
 - (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 */

@end