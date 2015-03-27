//
//  HTTPClient.m
//  GoogleImageSearch
//
//  Created by Firodiya, Sanket on 8/10/14.
//
//

#import "HTTPClient.h"
#import "GlobalConstants.h"

@implementation HTTPClient {
    NSString *searchTerm;
    NSMutableURLRequest *request;
    NSURLConnection *connection;
    NSMutableData *responseData;
    NSDictionary *responseDictionary;
}

+ (NSString *)GoogleImageSearchURLForSearchTerm:(NSString *)theSearchTerm atStartIndex:(NSInteger)theStartIndex{
    return [NSString stringWithFormat:@"%@?q=%@&v=1.0&start=%d&rsz=%d", URL_GOOGLEIMAGESEARCH, theSearchTerm, theStartIndex, RESULTS_PER_REQUEST];
}

- (void)queryGoogleImageAPIForSearchTerm:(NSString *)theSearchTerm atStartIndex:(NSInteger)theStartIndex {
    searchTerm = theSearchTerm;
    request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[[HTTPClient GoogleImageSearchURLForSearchTerm:theSearchTerm atStartIndex:theStartIndex] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]]];
    connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    responseData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    responseDictionary = [[NSDictionary alloc] init];
    responseDictionary = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:nil];
    if ([self.delegate respondsToSelector:@selector(resultsRetrieved:forSearchTerm:)]) {
        [self.delegate resultsRetrieved:responseDictionary forSearchTerm:searchTerm];
    }
    
}

@end
