//
//  HTTPClient.h
//  GoogleImageSearch
//
//  Created by Firodiya, Sanket on 8/10/14.
//
//

#import <Foundation/Foundation.h>

@protocol HTTPProtocol <NSObject, NSURLConnectionDelegate>
@optional
- (void)resultsRetrieved:(NSDictionary*)responseDictionary forSearchTerm:(NSString *)searchTerm;
@end

@interface HTTPClient : NSObject

@property (weak, nonatomic) id <HTTPProtocol>delegate;
- (void)queryGoogleImageAPIForSearchTerm:(NSString *)theSearchTerm atStartIndex:(NSInteger)theStartIndex ;


@end
