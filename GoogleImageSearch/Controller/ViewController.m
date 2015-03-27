//
//  ViewController.m
//  GoogleImageSearch
//
//  Created by Firodiya, Sanket on 8/9/14.
//
//

#import "ViewController.h"
#import "GlobalConstants.h"
#import "PhotoObject.h"

#define SEARCH_RESULTS_LIMIT 32

@interface ViewController ()
@property (nonatomic)  NSString *filePath;

@end

@implementation ViewController {
    NSMutableArray *arSearchHistory;
    NSMutableDictionary *dictSearchResults;
    NSString *currentSearchTerm;
}

#pragma mark - Setters

- (NSString *)filePath {
    if (!_filePath) {
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        _filePath = [documentsDirectory stringByAppendingPathComponent:@"SearchHistory.plist"];
    }
    return _filePath;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Image Search";
    arSearchHistory = [[NSMutableArray alloc] init];
    dictSearchResults = [[NSMutableDictionary alloc] init];
    [self.uiSearchBar becomeFirstResponder];
    [self registerForKeyboardNotifications];
    [self loadSearchHistory];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - UINavigationItem BarButtonItem methods

- (void)cancelTapped {
    self.uiSearchBar.text = currentSearchTerm;
    [self.uiSearchBar resignFirstResponder];
    [self.uiTableViewSearchHistory setContentOffset:CGPointZero animated:NO];
}

- (void)searchTapped {
    [self.uiSearchBar resignFirstResponder];
    
    if (self.uiSearchBar.text.length == 0 || [self.uiSearchBar.text isEqualToString:currentSearchTerm]) {
        return;
    }
    
    dictSearchResults = [[NSMutableDictionary alloc] init];
    [self.uiTableViewSearchHistory setContentOffset:CGPointZero animated:NO];
    [self.uiCollectionViewSearchResults setContentOffset:CGPointZero animated:NO];
    currentSearchTerm = self.uiSearchBar.text;
    [arSearchHistory insertObject:self.uiSearchBar.text atIndex:0];
    [arSearchHistory writeToFile:self.filePath atomically:YES];
    [self.uiCollectionViewSearchResults reloadData];
}

#pragma mark - Helper methods

- (void)loadSearchHistory {
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.filePath]) {
        [@{} writeToFile: self.filePath atomically: YES];
    } else {
        arSearchHistory = [[NSMutableArray alloc] initWithContentsOfFile:self.filePath];
        if (arSearchHistory == nil) {
            arSearchHistory = [[NSMutableArray alloc] init];
        }
    }
}

- (void)queryForImageAtIndex:(NSInteger)startIndex {
    HTTPClient *httpClient = [[HTTPClient alloc] init];
    httpClient.delegate = self;
    [httpClient queryGoogleImageAPIForSearchTerm:self.uiSearchBar.text atStartIndex:startIndex];
}

#pragma mark - UIKeyBoard delegate

- (void)registerForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeShown:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillBeShown:(NSNotification*)aNotification {
    self.uiSearchBar.text = @"";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelTapped)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Search" style:UIBarButtonItemStyleDone target:self action:@selector(searchTapped)];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    self.uiCollectionViewSearchResults.hidden = TRUE;
    self.uiTableViewSearchHistory.hidden = FALSE;
    [self.uiTableViewSearchHistory reloadData];
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification {
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.rightBarButtonItem = nil;
    self.uiCollectionViewSearchResults.hidden = FALSE;
    self.uiTableViewSearchHistory.hidden = TRUE;
}

#pragma mark - UISearchBar delegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self.uiSearchBar resignFirstResponder];
    [self searchTapped];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (searchText.length > 0) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    } else {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
}

#pragma mark - UICollectionView Datasource

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    return SEARCH_RESULTS_LIMIT;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    UIActivityIndicatorView *spinner = (UIActivityIndicatorView *)[cell viewWithTag:2];
    spinner.hidden = NO;
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:1];
    imageView.hidden = YES;
    
    if (currentSearchTerm.length == 0) {
        UIActivityIndicatorView *spinner = (UIActivityIndicatorView *)[cell viewWithTag:2];
        spinner.hidden = YES;
        return cell;
    }
    
    if ([dictSearchResults objectForKey:[NSNumber numberWithInteger:indexPath.row]]) {
        NSNumber *indexPathNumber = [NSNumber numberWithInteger:indexPath.row];
        PhotoObject *photoObject = [dictSearchResults objectForKey:indexPathNumber];
        if (photoObject.tbImage) {
            [self displayImageForCell:cell withPhoto:photoObject];
            
        } else {
            dispatch_queue_t secondaryQueue = dispatch_queue_create("com.GIS.imageDownload", NULL);
            dispatch_async(secondaryQueue, ^{
                UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:photoObject.tbUrl]];
                photoObject.tbImage = image;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self displayImageForCell:cell withPhoto:photoObject];
                });
            });
        }
        
    } else if (indexPath.row % RESULTS_PER_REQUEST == 0) { // Google Search API limits to 8 results for any query, we fire api queries only for indexes that we know were not covered in an earlier api result set
        if (self.uiSearchBar.text.length > 0) {
            [self queryForImageAtIndex:indexPath.row];
        }
    }
    
    return cell;
}

- (void)displayImageForCell:(UICollectionViewCell *)cell withPhoto:(PhotoObject *)photoObject {
    UIActivityIndicatorView *spinner = (UIActivityIndicatorView *)[cell viewWithTag:2];
    spinner.hidden = YES;
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:1];
    imageView.hidden = NO;
    
    CGRect frame = imageView.frame;
    frame.size.width = photoObject.tbImage.size.width;
    frame.size.height = photoObject.tbImage.size.height;
    imageView.frame = frame;
    imageView.image = photoObject.tbImage;
}

#pragma mark - UITableView Datasource

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 24;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (arSearchHistory.count > 0) {
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 24)];
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 2, tableView.frame.size.width, 24)];
        [headerLabel setFont:[UIFont boldSystemFontOfSize:12]];
        headerLabel.textColor = [UIColor whiteColor];
        headerLabel.text = @"SEARCH HISTORY";
        [headerView addSubview:headerLabel];
        [headerView setBackgroundColor:COLOR_SEARCHBARGRAY];
        return headerView;
    } else {
        return nil;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return arSearchHistory.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    cell.textLabel.text = [arSearchHistory objectAtIndex:indexPath.row];
    return cell;
}

#pragma mark - UITableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.uiSearchBar resignFirstResponder];
    NSString *searchText = [arSearchHistory objectAtIndex:indexPath.row];
    self.uiSearchBar.text = searchText;
    [self searchTapped];
}

#pragma mark - HTTPProtocol Delegate

- (void)resultsRetrieved:(NSDictionary*)responseDictionary forSearchTerm:(NSString *)searchTerm {
    
    if ([searchTerm isEqualToString:currentSearchTerm]) { // use results only if they are for current search, else throw away
        
        NSDictionary *responseData = responseDictionary[@"responseData"];
        if (responseData) {
            
            NSDictionary *cursor = [responseData objectForKey:@"cursor"];
            int startIndex = 0;
            if (cursor) {
                NSString *currentPageIndex = [cursor objectForKey:@"currentPageIndex"];
                startIndex = [currentPageIndex intValue] * RESULTS_PER_REQUEST;
            }
            
            NSArray *results = [responseData valueForKey:@"results"];
            
            if (results) {
                for (int i = 0; i < results.count; i++) {
                    NSString *tbUrl = [[results objectAtIndex:i] valueForKey:@"tbUrl"];
                    
                    PhotoObject *photoObject = [[PhotoObject alloc] initWithURL:[NSURL URLWithString:tbUrl]];
                    [dictSearchResults setObject:photoObject forKey:[NSNumber numberWithInteger:startIndex]];
                    [self.uiCollectionViewSearchResults reloadItemsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:startIndex inSection:0]]];
                    startIndex ++;
                }
            }
        }
    }
}

@end
