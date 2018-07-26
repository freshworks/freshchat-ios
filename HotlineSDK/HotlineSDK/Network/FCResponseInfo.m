//
//  FDResponseInfo.h
//  HotlineSDK
//
//  Created by Aravinth Chandran on 27/01/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "FCResponseInfo.h"

@interface FCResponseInfo ()

@property (nonatomic, strong) id responseBody;
@end

@implementation FCResponseInfo

-(instancetype)initWithResponse:(NSURLResponse *)response andHTTPBody:(NSData *)data{
    self = [super init];
    if (self) {
        self.response = response;
        if(data){
            self.responseBody = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        }
    }
    return self;
}

-(BOOL)isArray{
    return [self.responseBody isKindOfClass:[NSArray class]];
}

-(BOOL)isDict{
    return [self.responseBody isKindOfClass:[NSDictionary class]];
}

-(NSDictionary *)responseAsDictionary {
    return (NSDictionary *)self.responseBody;
}

-(NSArray *)responseAsArray{
    return (NSArray *)self.responseBody;
}

-(NSString *)toString{
    return [NSString stringWithFormat:@"HEADERS : %@ RESPONSE: %@ HTTP-BODY:%@", [(NSHTTPURLResponse *)self.response allHeaderFields] , self.response, self.responseBody];
}

@end
