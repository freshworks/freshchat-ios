//
//  FDIndex.h
//  Hotline
//
//  Created by user on 30/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#define HOTLINE_DB_INDEX_ARTICLE_ID    @"articleID"
#define HOTLINE_DB_INDEX_KEY_WORD      @"keyWord"
#define HOTLINE_DB_INDEX_TITLE_MATCHES @"titleMatches"
#define HOTLINE_DB_INDEX_DESC_MATCHES  @"descMatches"

NS_ASSUME_NONNULL_BEGIN

@interface FCFAQSearchIndex : NSManagedObject

@property (nonatomic, retain) NSNumber * articleID;
@property (nonatomic, retain) NSString * keyWord;
@property (nonatomic, retain) NSNumber * titleMatches;
@property (nonatomic, retain) NSNumber * descMatches;

+(NSMutableArray *)indexWithInfo:(NSDictionary *)indexInfo inManagedObjectContext:(NSManagedObjectContext *)context withArticleID:(NSNumber *)articleID;

@end

NS_ASSUME_NONNULL_END

