//
//  ViewController.h
//  GoogleImageSearch
//
//  Created by Firodiya, Sanket on 8/9/14.
//
//

#import <UIKit/UIKit.h>
#import "HTTPClient.h"

@interface ViewController : UIViewController<UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, HTTPProtocol>
@property (weak, nonatomic) IBOutlet UISearchBar *uiSearchBar;
@property (weak, nonatomic) IBOutlet UICollectionView *uiCollectionViewSearchResults;
@property (weak, nonatomic) IBOutlet UITableView *uiTableViewSearchHistory;

@end
