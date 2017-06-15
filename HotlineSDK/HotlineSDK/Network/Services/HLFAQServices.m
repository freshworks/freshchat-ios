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
#import "FDResponseInfo.h"
#import "FDDateUtil.h"
#import "HLTagManager.h"
#import "HLTags.h"
#import "HLUserDefaults.h"
#import "FDLocaleUtil.h"
#import "FDConstants.h"

@implementation HLFAQServices

-(NSURLSessionDataTask *)fetchAllCategories:(void (^)(NSError *))completion{
    static BOOL CATEGORIES_DOWNLOAD_IN_PROGRESS = NO;
    if (CATEGORIES_DOWNLOAD_IN_PROGRESS) {
        FDLog(@"download solution in progress, so skip");
        if(completion){
            completion(nil);
        }
        return nil;
    }
    CATEGORIES_DOWNLOAD_IN_PROGRESS = YES;
    HLAPIClient *apiClient = [HLAPIClient sharedInstance];
    FDSecureStore *store = [FDSecureStore sharedInstance];
    HLServiceRequest *request = [[HLServiceRequest alloc]initWithMethod:HTTP_METHOD_GET];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *appKey = [store objectForKey:HOTLINE_DEFAULTS_APP_KEY];
    NSString *path = [NSString stringWithFormat:HOTLINE_API_CATEGORIES_PATH,appID];
    NSString *token = [NSString stringWithFormat:HOTLINE_REQUEST_PARAMS,appKey];
    
    NSNumber *lastUpdateTime = [FDUtilities getLastUpdatedTimeForKey:HOTLINE_DEFAULTS_SOLUTIONS_LAST_UPDATED_SERVER_TIME];
    NSNumber *requestlocaleId = [FDLocaleUtil getContentLocaleId];
    NSString *afterTime = [NSString stringWithFormat:PARAM_SINCE,lastUpdateTime];
    NSMutableArray *reqParams = [[NSMutableArray alloc]initWithArray:@[token,afterTime,PARAM_PLATFORM_IOS]];
    [reqParams addObjectsFromArray:[FDLocaleUtil userLocaleParams:NO]];
    [request setRelativePath:path andURLParams:reqParams];
    [request setValue:[lastUpdateTime stringValue]  forHTTPHeaderField:IF_MODIFIED_SINCE];
    
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(FDResponseInfo *responseInfo, NSError *error) {
        NSInteger statusCode = ((NSHTTPURLResponse *)responseInfo.response).statusCode;
        if(!error && statusCode == 200) {
            KonotorDataManager *dataManager = [KonotorDataManager sharedInstance];
            [dataManager deleteAllFAQ:^(NSError *error) {
                if(!error) {
                    FDLog(@"All faq deleted");
                    [self importSolutions:[responseInfo responseAsDictionary]withCompletion:^(NSError *error) {
                        if(!error && responseInfo){
                            
                            //Updating contentLocaleid and drop voted articles
                            NSMutableDictionary *dictionary = [responseInfo responseAsDictionary][CONTENT_LOCALE];
                            NSNumber *responseLocaleId = [dictionary objectForKey:@"localeId"];
                            if( ![requestlocaleId isEqualToNumber:responseLocaleId] ) {
                                [HLUserDefaults setNumber:responseLocaleId forKey:HOTLINE_DEFAULTS_CONTENT_LOCALEID];
                                [[FDSecureStore sharedInstance] removeObjectWithKey:HOTLINE_DEFAULTS_VOTED_ARTICLES];
                                FDLog(@"LocaleID changed from %@ -> %@ & Cleared Voted Articles",[FDLocaleUtil getContentLocaleId],responseLocaleId);
                            }
                            
                            //Updating userLocale
                            if([FDLocaleUtil hadLocaleChange]) {
                                NSString *localLocale = [FDLocaleUtil getLocalLocale];
                                [FDLocaleUtil updateLocale:localLocale];
                            }
                            
                            NSArray *categories = [responseInfo responseAsDictionary][@"categories"];
                            if(categories && categories.count > 0 ){
                                [FDIndexManager setIndexingCompleted:NO];
                                [FDIndexManager updateIndex];
                            }
                            [FDLocalNotification post:HOTLINE_SOLUTIONS_UPDATED];
                        }
                        if(completion){
                            completion(error);
                            CATEGORIES_DOWNLOAD_IN_PROGRESS = NO;
                            FDLog(@"All solutions hopefully added again.");
                        }
                    }];
                }
                else {
                    CATEGORIES_DOWNLOAD_IN_PROGRESS = NO;
                     if(completion){
                         completion(error);
                         FDLog(@"Problem in adding the new faq.");
                     }
                }
            }];
        }
        else { // 304 not updated also comes here
            if(completion){
                completion(error);
            }
            [FDLocalNotification post:HOTLINE_SOLUTIONS_UPDATED];
            CATEGORIES_DOWNLOAD_IN_PROGRESS = NO;
        }
        
    }];
    return task;
}

-(void)importSolutions:(NSDictionary *)solutions withCompletion:(void (^)(NSError *))completion{
    NSManagedObjectContext *context = [KonotorDataManager sharedInstance].backgroundContext;
    [context performBlock:^{
        NSArray *categories = solutions[@"categories"];
        for(int i=0; i<categories.count; i++){
            NSDictionary *categoryInfo = categories[i];
            HLCategory *category = [HLCategory getWithID:categoryInfo[@"categoryId"] inContext:context];
            BOOL isCategoryEnabled = [categoryInfo[@"enabled"]boolValue];
            BOOL isIOSPlatformAvail = [categoryInfo[@"platforms"] containsObject:@"ios"];
            NSArray *tags = categoryInfo[@"tags"];
            [HLTags removeTagsForTaggableId:categoryInfo[@"categoryId"] andType:[NSNumber numberWithInt: HLTagTypeCategory] inContext:context];
            if (isCategoryEnabled && isIOSPlatformAvail) {
                if (category) {
                    FDLog(@"Updating category:%@ [%@abled]", categoryInfo[@"title"], ( isCategoryEnabled ? @"en" : @"dis"));
                    [category updateWithInfo:categoryInfo];
                }else{
                    FDLog(@"New category:%@ [%@abled]", categoryInfo[@"title"], ( isCategoryEnabled ? @"en" : @"dis"));
                    category = [HLCategory createWithInfo:categoryInfo inContext:context];
                }
                
                if(tags.count>0){
                    for(NSString *tagName in tags){
                        [HLTags createTagWithInfo:[HLTags createDictWithTagName:tagName type:[NSNumber numberWithInt: HLTagTypeCategory] andIdvalue:categoryInfo[@"categoryId"]] inContext:context];
                    }
                }
            }else{
                if (category){
                    FDLog(@"Deleting category with title : %@ with ID : %@ because its disabled !",category.title, category.categoryID);
                    [context deleteObject:category];
                }
            }
        }
        
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_CATEGORY_ENTITY];
        NSArray *allCategories = [context executeFetchRequest:request error:nil];
        for(HLCategory *category in allCategories){
            if(category.articles.count == 0){
                FDLog(@"Deleting category with title : %@ with ID : %@ because it doesn't contain any articles !"
                      ,category.title, category.categoryID);
                [HLTags removeTagsForTaggableId:category.categoryID andType:[NSNumber numberWithInt: HLTagTypeCategory] inContext:context];
                [context deleteObject:category];
            }
        }
        
        NSError *err;
        [context save:&err];
        [[FDSecureStore sharedInstance] setObject:solutions[LAST_MODIFIED_AT] forKey:HOTLINE_DEFAULTS_SOLUTIONS_LAST_UPDATED_SERVER_TIME];
        if(completion){
            completion(err);
        }
    }];
}

-(NSURLSessionDataTask *)vote:(BOOL)vote forArticleID:(NSNumber *)articleID inCategoryID:(NSNumber *)categoryID{
    HLAPIClient *apiClient = [HLAPIClient sharedInstance];
    FDSecureStore *store = [FDSecureStore sharedInstance];
    HLServiceRequest *request = [[HLServiceRequest alloc]initWithMethod:HTTP_METHOD_PUT];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *path = [NSString stringWithFormat:HOTLINE_API_ARTICLE_VOTE_PATH,appID,categoryID,articleID];
    NSString *appKey = [store objectForKey:HOTLINE_DEFAULTS_APP_KEY];
    NSString *token = [NSString stringWithFormat:HOTLINE_REQUEST_PARAMS,appKey];
    NSMutableArray *reqParams = [[NSMutableArray alloc]initWithArray:@[token,PARAM_PLATFORM_IOS]];
    [reqParams addObjectsFromArray:[FDLocaleUtil userLocaleParams:YES]];
    [request setRelativePath:path andURLParams:reqParams];
    NSDictionary *voteInfo;
    if (vote) {
        voteInfo = @{ @"upvote" : @1 };
    }else{
        voteInfo = @{ @"downvote" : @1 };
    }
    NSData *postData = [NSJSONSerialization dataWithJSONObject:voteInfo options:0 error:nil];
    [request setBody:postData];
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(FDResponseInfo *responseInfo,NSError *error) {
        NSInteger statusCode = ((NSHTTPURLResponse *)responseInfo.response).statusCode;
        if(!error && statusCode == 200) {
            FDLog(@"Article vote successful");
        }else{
            FDLog(@"Article voting failed :%@", error);
            FDLog(@"Response %@", responseInfo.response);
        }
    }];
    return task;
}

@end
