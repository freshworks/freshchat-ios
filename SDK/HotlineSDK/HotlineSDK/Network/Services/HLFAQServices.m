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
#import "KonotorDataManager.h"
#import "HLArticle.h"
#import "HLCategory.h"
#import "FDLocalNotification.h"
#import "FDSecureStore.h"

@implementation HLFAQServices

-(NSURLSessionDataTask *)fetchSolutions{
    HLAPIClient *apiClient = [HLAPIClient sharedInstance];
    NSURL *URL = [NSURL URLWithString:HOTLINE_API_CATEGORIES];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    NSURLSessionDataTask *task = [apiClient GET:request withHandler:^(id responseObject, NSError *error) {
        __block BOOL canAbortRequest = NO;
        __block NSMutableArray *solutions = [NSMutableArray new];
        dispatch_group_t group = dispatch_group_create();
        NSArray *categories = responseObject[@"categories"];

        for (int i=0; i<categories.count; i++) {
            
            if (canAbortRequest) {
                break;
            }
            
            dispatch_group_enter(group);
            
            if (NO) { // If fetch not required for a particular category
                dispatch_group_leave(group);
                continue;
            }
            
            
            NSDictionary *categoryInfo = categories[i];
            NSString *categoryID = categoryInfo[@"categoryId"];
            NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:HOTLINE_API_ARTICLES,categoryID]];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
            [apiClient GET:request withHandler:^(id responseObject, NSError *error) {
                if (!error) {
                    [solutions addObject:@{ @"category" : categoryInfo, @"articles" : responseObject[@"articles"]}];
                }else{
                    canAbortRequest = YES;
                }
                dispatch_group_leave(group);
            }];
        }
        
        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            if (!canAbortRequest) {
                [[KonotorDataManager sharedInstance]deleteAllSolutions:^(NSError *error) {
                    if (!error) {
                        [[FDSecureStore sharedInstance] setObject:[NSDate date] forKey:HOTLINE_DEFAULTS_SOLUTIONS_LAST_UPDATED_TIME];
                        [self updateDBWithSolutions:solutions];
                    }
                }];
            }
        });
    }];
    return task;
}

-(void)updateDBWithSolutions:(NSArray *)solutions{
    NSManagedObjectContext *context = [KonotorDataManager sharedInstance].backgroundContext;
    [context performBlock:^{
        for (int i=0; i<solutions.count; i++){
            NSDictionary *categoryInfo = solutions[i][@"category"];
            HLCategory *category = [HLCategory categoryWithInfo:categoryInfo inManagedObjectContext:context];
            __block NSData *imageData = nil;
            dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:category.iconURL]];
            });
            category.icon = imageData;
            NSArray *articles = solutions[i][@"articles"];
            for (int j=0; j<articles.count; j++) {
                NSDictionary *articleInfo = articles[j];
                HLArticle *article = [HLArticle articleWithInfo:articleInfo inManagedObjectContext:context];
                [category addArticlesObject:article];
            }
        }
        [context save:nil];
        NSLog(@"Fetched Solutions %@",solutions);
        [self postNotification];
    }];
}

-(NSURLSessionDataTask *)downVoteFor:(NSNumber *)articleID inCategory:(NSNumber *)categoryID{
    HLAPIClient *apiClient = [HLAPIClient sharedInstance];
    NSString *URLString = [NSString stringWithFormat:HOTLINE_API_ARTICLE_VOTE,categoryID,articleID];
    NSURL *URL = [NSURL URLWithString:URLString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    NSDictionary *voteDictionary = @{@"article":
                                     @{
                                         @"upvote":@"-1",
                                         @"downvote":@"1"
                                     }
                                    };
    NSData *postData = [NSJSONSerialization dataWithJSONObject:voteDictionary options:0 error:nil];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    [request setHTTPMethod:@"PUT"];

    [request setHTTPBody:postData];
    NSURLSessionDataTask *task = [apiClient PUT:request withHandler:^(id responseObject, NSError *error) {
        NSLog(@"Upvote response : %@",responseObject);
    }];
    return task;
}

-(NSURLSessionDataTask *)upVoteFor:(NSNumber *)articleID inCategory:(NSNumber *)categoryID{
    HLAPIClient *apiClient = [HLAPIClient sharedInstance];
    NSString *URLString = [NSString stringWithFormat:HOTLINE_API_ARTICLE_VOTE,categoryID,articleID];
    NSURL *URL = [NSURL URLWithString:URLString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    NSDictionary *voteDictionary = @{@"article":
                                         @{
                                             @"upvote":@"1",
                                             @"downvote":@"-1"
                                             }
                                     };
    NSData *postData = [NSJSONSerialization dataWithJSONObject:voteDictionary options:0 error:nil];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    [request setHTTPMethod:@"PUT"];
    
    [request setHTTPBody:postData];
    NSURLSessionDataTask *task = [apiClient PUT:request withHandler:^(id responseObject, NSError *error) {
        NSLog(@"Upvote response : %@",responseObject);
    }];
    return task;
}

-(void)postNotification{
    [[NSNotificationCenter defaultCenter] postNotificationName:HOTLINE_SOLUTIONS_UPDATED object:self];
}

@end