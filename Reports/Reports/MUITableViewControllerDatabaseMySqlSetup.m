//
//  UITableViewControllerDataSourceSetupMySql.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MUITableViewControllerDatabaseMySqlSetup.h"

@interface MUITableViewControllerDatabaseMySqlSetup()

@end

@implementation MUITableViewControllerDatabaseMySqlSetup

- (void)dealloc {
    [_tableViewCellUsername release];
    [_tableViewCellPassword release];
    [_tableViewCellHost release];
    [_tableViewCellPort release];
    [_tableViewCellTestConnection release];
    [_activityIndicatorTestConnection release];
    [_textFieldUsername release];
    [_textFieldPassword release];
    [_textFieldHost release];
    [_textFieldPort release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
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

    [[self navigationItem] setPrompt: NSLocalizedString(@"Set inital settings.", @"Set inital settings.")];
    [self setTitle: NSLocalizedString(@"New Report", @"New Report")];
    
    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = YES;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Actions

- (const char *)cStringFromString:(NSString *)theString {       
    NSMutableData *theData;
    NSLog(@"theString, %@", theString);
    if (! theString) {
        return (const char *)NULL;
    }
    
    theData = [NSMutableData dataWithData:[theString dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
    [theData increaseLengthBy:1];
    return (const char *)[theData bytes];
}

- (void)test:(id)sender {
#warning Commenting this shit out
    
    /*
    //NSDatabaseMySql *db = [[NSDatabaseMySql alloc] initWithHost:@"everydayapps.com" port:3363 username:@"root" andPassword:@"1noniceguy"];

    //NSArray *s = [[db tablesFor:@"quotationary"] retain];
    //NSLog(@"Tables %@", s);
    //[s release];
    
    //[db release];

    MYSQL conn;
    mysql_init(&conn);
    //long flags = MYSQL_DEFAULT_CONNECTION_FLAGS;
    //mysql_options(&(connection->conn), MYSQL_READ_DEFAULT_GROUP, "libmysqlclient.a");
    mysql_real_connect(&conn, "everydayapps.com", "root", "1noniceguy", "quotationary", 3306, NULL, 0);
    
    //NSString *q = @"SELECT table_name FROM information_schema.tables WHERE table_schema = '%s'; ";
    char query[1024];
    sprintf(query, "SELECT table_name FROM information_schema.tables WHERE table_schema = '%s'; ", "quotationary");// (const char *)[database UTF8String]);
    NSLog(@"query %s", query);
    mysql_query(&conn, query);
    
    MYSQL_RES *result = mysql_store_result(&conn);
    NSMutableSet *mutableResult = nil;
    
    if (result != NULL) {
        //int num_rows = mysql_num_rows(result);
        mutableResult = [[NSMutableSet alloc] initWithCapacity:300];
        
        //@autoreleasepool {
        MYSQL_ROW row;
        //@autoreleasepool {
        //mysql_fetch_row(result);
        //printf("row %s", row[0]);
        //@autoreleasepool {
        while ((row = mysql_fetch_row(result))) {
            //NSLog(@"Got row");
            if (row[0]) {
                NSLog(@"N: %@, K: %@", [NSString stringWithUTF8String:row[0]], [NSString stringWithUTF8String:row[0]]);                    
            } else {
                //NSLog(@"Not got row!!!");
            }
            //}
        }
        
        [mutableResult autorelease];
        
        
        mysql_free_result(result);
    }    
    mysql_close(&conn);
    mysql_server_end();
    
    
    
    //NSString *username = [[NSString alloc] initWithString: [[self textFieldUsername] text]];
    //NSString *password = [[NSString alloc] initWithString: [[self textFieldPassword] text]];
    //NSString *host = [[NSString alloc] initWithString: [[self textFieldHost] text]];
    //NSString *port = [[[self textFieldPort] text] retain];
    //NSDictionary *credentals = [[NSDictionary alloc] initWithObjectsAndKeys:
    //                            username, NSDATABASE_USERNAME,
    //                            password, NSDATABASE_PASSWORD,
    //                            host, NSDATABASE_HOST,
    //                            [NSNumber numberWithInteger: [port integerValue]], NSDATABASE_PORT, nil];

    
    //NSMutableSet *mutableResult = [[NSMutableSet alloc] init];
    //@autoreleasepool {
    //const char * theSocket = MYSQL_UNIX_ADDR;
    
    //[[self inputHost] setString: [[self textFieldHost] text]];
    //[[self inputUsername] setString: [[self textFieldUsername] text]];
    //[[self inputPassword] setString: [[self textFieldPassword] text]];
    //[[self inputPort] setString: [[self textFieldPort] text]];
    
    //const char * ho = [self cStringFromString: [self inputHost]];
    //const char * un = [self cStringFromString: [self inputUsername]];
    //const char * pw = [self cStringFromString: [self inputPassword]];
    //int po = [[self inputPort] intValue];
        
    //self.conn = mysql_init(NULL); 
    
    //my_bool reconnect = YES;
    //mysql_options(self.conn, MYSQL_OPT_RECONNECT, &reconnect);
    //mysql_real_connect(self.conn, ho, un, pw, NULL, po, NULL, CLIENT_COMPRESS);
        
        
        //mysql_close(conn); 
    //}
    */
    /*

    MYSQL *conn = mysql_init(NULL);
    //const char *h = [[self host] UTF8String];
    

    mysql_real_connect(conn, [[[self textFieldHost] text] UTF8String], [[[self textFieldUsername] text] UTF8String], [[[self textFieldPassword] text] UTF8String], NULL, [[[self textFieldPort] text] intValue], NULL, 0);
    
    
    NSString *q = @"SELECT table_name FROM information_schema.tables WHERE table_schema = '%s'; ";
    char query[[q length] + 12];
    sprintf(query, "SELECT table_name FROM information_schema.tables WHERE table_schema = '%s'; ", "quotationary");// (const char *)[database UTF8String]);
    NSLog(@"query %s", query);

    mysql_query(conn, query);
    

     MYSQL_RES *result = mysql_store_result(conn);

    
    if (result) {
        //mutableResult = [[NSMutableSet alloc] initWithCapacity:mysql_num_rows(result)];
        
        //@autoreleasepool {
        MYSQL_ROW row;
        //@autoreleasepool {
        //mysql_fetch_row(result);
        //printf("row %s", row[0]);
        while ((row = mysql_fetch_row(result))) {
            NSLog(@"Got row");
            if (row[0]) {
                NSString *name = [[NSString alloc] initWithUTF8String:row[0]];
                if (name) {
                    //[mutableResult addObject: name];
                } else {
                    NSLog(@"Not got name");
                }
                NSLog(@"row %s", row[0]);
                NSLog(@"name %@", name);
                [name release];
                
            } else {
                NSLog(@"Not got row!!!");
            }
             
        }
        //}
        mysql_free_result(result);
    }
    mysql_close(conn);
    
    */
    //NSDatabaseMySql *db = [[NSDatabaseMySql alloc] initWithOptions: credentals];

    
    /*
    NSDatabaseMySql *db = [[NSDatabaseMySql alloc] initWithHost:host port:[port integerValue] username:username andPassword:password];

    
    

    
    //BOOL result = [db testConnection];
    //NSLog(@"result: %@", result ? @"YES" : @"NO");
    
    [UIView animateWithDuration:ANIMATION_DURATION_SLOW delay:ANIMATION_DURATION_NONE options:UIViewAnimationOptionCurveEaseIn animations:^{
        [[self tableViewCellTestConnection] setBackgroundColor: result ? [UIColor greenColor] : [UIColor redColor]];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:ANIMATION_DURATION_SLOW delay:ANIMATION_DURATION_NONE options:UIViewAnimationOptionCurveEaseIn animations:^{
            if (finished) [[self tableViewCellTestConnection] setBackgroundColor: [UIColor whiteColor]];
        } completion:^(BOOL finished) { }];
    }];
    
    [username release];
    [password release];
    [host release];
    [port release];

    [db release];
    
    */
    
    NSLog(@"Database released");
    //[credentals release];
    NSLog(@"Credentals released");
}

- (IBAction)save:(id)sender {
    /*
    //Create UIManaged Document that Stores the Database Schema
#warning What is this trash!?!
    //Create UIManaged Document that Stores the Database Schema
    if ([[[self textFieldNickname] text] length] > 0) {
        [[self saveButton] setEnabled: NO];
        NSDatabaseMySql *d = [[NSDatabaseSalesForce alloc] initNewFileWithName: [[self textFieldNickname] text] completion: ^(BOOL success) {
            success ?
            [[[self navigationController] presentingViewController] dismissModalViewControllerAnimated: YES] :
            [[self saveButton] setEnabled: YES];
        }];
        [d setDelegate: self];
        [self setDb:d];
        [d release];
        
    } else {
        [UIView animateWithDuration:ANIMATION_DURATION_FAST animations:^{
            [[[self tableViewCellNickname] contentView] setBackgroundColor:[UIColor edaOrange]];
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:ANIMATION_DURATION_FAST animations:^{
                [[[self tableViewCellNickname] contentView] setBackgroundColor:[UIColor clearColor]];
            } completion:^(BOOL finished) {
                
            }];
        }];
    }    [[[self navigationController] presentingViewController] dismissModalViewControllerAnimated: YES];
     */
}

- (IBAction)done:(id)sender {
    [[self delegate] viewControllerDidFinish: self];
}

- (IBAction)usernameDidEndOnExit:(id)sender {
/*    if ([sender isKindOfClass: [UITextField class]]) {
        [self setInputUsername:[(UITextField *)sender text]];
    }
    if ([[self textFieldPassword] canBecomeFirstResponder]) {
        [[self textFieldPassword] becomeFirstResponder];
    }*/
}

- (IBAction)passwordDidEndOnExit:(id)sender {
    if ([[self textFieldHost] canBecomeFirstResponder]) {
        [[self textFieldHost] becomeFirstResponder];
    }
}

- (IBAction)hostDidEndOnExit:(id)sender {
    if ([[self textFieldPort] canBecomeFirstResponder]) {
        [[self textFieldPort] becomeFirstResponder];
    }
}

- (IBAction)portDidEndOnExit:(id)sender {
    [[self textFieldPort] resignFirstResponder];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath: indexPath animated: YES];
    if ([[tableView cellForRowAtIndexPath: indexPath] isEqual: [self tableViewCellTestConnection]]) {
        NSLog(@"Test connection!!!");
        [self test:nil];
        NSLog(@"Did finish test connection");
    }
}

@end