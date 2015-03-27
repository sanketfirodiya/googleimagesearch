//
//  PhotoObject.m
//  GoogleImageSearch
//
//  Created by Firodiya, Sanket on 8/10/14.
//
//

#import "PhotoObject.h"

@implementation PhotoObject

- (id)initWithURL:(NSURL *)Url {
    if ((self = [super init])) {
        self.tbUrl = Url;
    }
    return self;
}

@end
