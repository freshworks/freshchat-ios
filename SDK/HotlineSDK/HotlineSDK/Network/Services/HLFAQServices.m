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
#import "HLLocalNotification.h"

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
                [self deleteExistingSolutions];
                [self updateDBWithSolutions:solutions];
                [self postNotification];
            }
        });
    }];
    return task;
}

-(void)deleteExistingSolutions{
    [[KonotorDataManager sharedInstance]deleteAllSolutions];
}

-(void)updateDBWithSolutions:(NSArray *)solutions{
    NSManagedObjectContext *context = [KonotorDataManager sharedInstance].mainObjectContext;
    for (int i=0; i<solutions.count; i++){
        NSDictionary *categoryInfo = solutions[i][@"category"];
        HLCategory *category = [HLCategory categoryWithInfo:categoryInfo inManagedObjectContext:context];
        NSArray *articles = solutions[i][@"articles"];
        for (int j=0; j<articles.count; j++) {
            NSDictionary *articleInfo = articles[j];
            HLArticle *article = [HLArticle articleWithInfo:articleInfo inManagedObjectContext:context];
            [category addArticlesObject:article];
        }
    }
    [[KonotorDataManager sharedInstance]save];
    NSLog(@"All done successfully, Solutions %@",solutions);
}

-(void)postNotification{
    [[NSNotificationCenter defaultCenter] postNotificationName:HOTLINE_SOLUTIONS_UPDATED object:self];
}

@end