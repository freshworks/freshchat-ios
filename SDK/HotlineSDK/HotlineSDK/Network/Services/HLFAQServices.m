//
//  HLFAQServices.m
//  
//
//  Created by Aravinth Chandran on 21/09/15.
//
//

#import "HLFAQServices.h"
#import "HLAPIClient.h"
#import "HLAPI.h"

@implementation HLFAQServices

-(NSURLSessionDataTask *)fetchSolutions{
    HLAPIClient *apiClient = [HLAPIClient sharedInstance];
    NSURL *URL = [NSURL URLWithString:HOTLINE_API_CATEGORIES];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    [apiClient GET:request withHandler:^(id responseObject, NSError *error) {
        NSLog(@"Response %@", responseObject);
    }];
    return nil;
}

@end
