//
//  PhotoObject.h
//  GoogleImageSearch
//
//  Created by Firodiya, Sanket on 8/10/14.
//
//

#import <Foundation/Foundation.h>

@interface PhotoObject : NSObject
@property (retain) NSURL * tbUrl;
@property (nonatomic, retain) UIImage * tbImage;
- (id)initWithURL:(NSURL *)Url;
@end
