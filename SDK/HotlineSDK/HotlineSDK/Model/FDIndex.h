//
//  FDIndex.h
//  FreshdeskSDK
//
//  Created by kirthikas on 29/01/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#define MOBIHELP_DB_INDEX_ARTICLE_ID    @"articleID"
#define MOBIHELP_DB_INDEX_KEY_WORD      @"keyWord"
#define MOBIHELP_DB_INDEX_TITLE_MATCHES @"titleMatches"
#define MOBIHELP_DB_INDEX_DESC_MATCHES  @"descMatches"



@interface FDIndex : NSManagedObject

@property (nonatomic, retain) NSNumber * articleID;
@property (nonatomic, retain) NSString * keyWord;
@property (nonatomic, retain) NSNumber * titleMatches;
@property (nonatomic, retain) NSNumber * descMatches;

+(NSMutableArray *)indexWithInfo:(NSDictionary *)indexInfo inManagedObjectContext:(NSManagedObjectContext *)context withArticleID:(NSNumber *)articleID;


@end
