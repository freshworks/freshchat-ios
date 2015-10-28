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
#import "HLServiceRequest.h"
#import "HLMacros.h"
#import "FDUtilities.h"
#import "FDIndexManager.h"

@implementation HLFAQServices

-(NSURLSessionDataTask *)fetchAllCategories{
    HLAPIClient *apiClient = [HLAPIClient sharedInstance];
    HLServiceRequest *request = [[HLServiceRequest alloc]initWithBaseURL:[NSURL URLWithString:HOTLINE_USER_DOMAIN]];
    request.HTTPMethod = HTTP_METHOD_GET;
    NSString *appID = @"0e611e03-572a-4c49-82a9-e63ae6a3758e";
    NSString *token = [NSString stringWithFormat:HOTLINE_REQUEST_PARAMS,@"be346b63-59d7-4cbc-9a47-f3a01e35f093"];
    NSString *path = [NSString stringWithFormat:HOTLINE_API_CATEGORIES,appID];
    [request setRelativePath:path andURLParams:@[token, @"deep=true"]];
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(id responseObject, NSError *error) {
        [self importSolutions:responseObject];
        [FDIndexManager updateIndex];
        [[FDSecureStore sharedInstance] setObject:[NSDate date] forKey:HOTLINE_DEFAULTS_SOLUTIONS_LAST_UPDATED_TIME];
    }];
    return task;
}

-(void)importSolutions:(NSDictionary *)solutions{
    NSManagedObjectContext *context = [KonotorDataManager sharedInstance].backgroundContext;
    [context performBlock:^{
        NSArray *categories = solutions[@"categories"];
        for(int i=0; i<categories.count; i++){
            NSDictionary *categoryInfo = categories[i];
            HLCategory *category = [HLCategory getWithID:categoryInfo[@"categoryId"] inContext:context];
            BOOL isCategoryEnabled = [categoryInfo[@"enabled"]boolValue];
            if (isCategoryEnabled) {
                if (category) {
                    NSDate *updateTime = [NSDate dateWithTimeIntervalSince1970:[categoryInfo[@"lastUpdatedAt"]doubleValue]];
                    if ([category.lastUpdatedTime compare:updateTime] == NSOrderedAscending) {
                        [category updateWithInfo:categoryInfo];
                        FDLog(@"Category with ID:%@ updated", categoryInfo[@"categoryId"]);
                    }
                }else{
                    category = [HLCategory createWithInfo:categoryInfo inContext:context];
                }
            }else{
                if (category) [context deleteObject:category];
            }
        }
        [context save:nil];
        [self postNotification];
    }];
}

-(NSURLSessionDataTask *)vote:(BOOL)vote forArticleID:(NSNumber *)articleID inCategoryID:(NSNumber *)categoryID{
    HLAPIClient *apiClient = [HLAPIClient sharedInstance];
    HLServiceRequest *request = [[HLServiceRequest alloc]initWithBaseURL:[NSURL URLWithString:HOTLINE_USER_DOMAIN]];
    NSString *appID = @"0e611e03-572a-4c49-82a9-e63ae6a3758e";
    NSString *path = [NSString stringWithFormat:HOTLINE_API_ARTICLE_VOTE,appID,categoryID,articleID];
    request.HTTPMethod = HTTP_METHOD_PUT;
    NSString *token = [NSString stringWithFormat:HOTLINE_REQUEST_PARAMS,@"be346b63-59d7-4cbc-9a47-f3a01e35f093"];
    [request setRelativePath:path andURLParams:@[token, @"deep=true", @"platform=ios"]];
    NSDictionary *voteInfo;
    if (vote) {
        voteInfo = @{ @"article": @{ @"upvote" : @"1", @"downvote" : @"-1" } };
    }else{
        voteInfo = @{ @"article": @{ @"upvote" : @"-1", @"downvote" : @"1" } };
    }
    NSData *postData = [NSJSONSerialization dataWithJSONObject:voteInfo options:0 error:nil];
    request.HTTPBody = postData;
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(id responseObject, NSError *error) {
        FDLog(@"Article vote status: %@",responseObject);
    }];
    return task;
}

-(void)postNotification{
    [[NSNotificationCenter defaultCenter] postNotificationName:HOTLINE_SOLUTIONS_UPDATED object:self];
}

-(NSURLSessionDataTask *)fetchCategoriesInBatches{
    HLAPIClient *apiClient = [HLAPIClient sharedInstance];
    HLServiceRequest *request = [[HLServiceRequest alloc]initWithBaseURL:[NSURL URLWithString:HOTLINE_USER_DOMAIN]];
    request.HTTPMethod = HTTP_METHOD_GET;
    NSString *appID = @"0e611e03-572a-4c49-82a9-e63ae6a3758e";
    NSString *token = [NSString stringWithFormat:HOTLINE_REQUEST_PARAMS,@"be346b63-59d7-4cbc-9a47-f3a01e35f093"];
    NSString *path = [NSString stringWithFormat:HOTLINE_API_CATEGORIES,appID];
    [request setRelativePath:path andURLParams:@[token]];
    
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(id responseObject, NSError *error) {
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
            NSString *path = [NSString stringWithFormat:HOTLINE_API_ARTICLES,appID, categoryID];
            NSString *token = [NSString stringWithFormat:HOTLINE_REQUEST_PARAMS,@"be346b63-59d7-4cbc-9a47-f3a01e35f093"];
            [request setRelativePath:path andURLParams:@[token]];
            [apiClient request:request withHandler:^(id responseObject, NSError *error) {
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
                    }
                }];
            }
        });
    }];
    return task;
}

@end