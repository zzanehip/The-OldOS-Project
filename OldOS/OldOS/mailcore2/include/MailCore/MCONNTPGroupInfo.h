//
//  MCONNTPGroupInfo.h
//  mailcore2
//
//  Created by Robert Widmann on 8/13/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCONNTPGROUPINFO_H

#define MAILCORE_MCONNTPGROUPINFO_H

#import <Foundation/Foundation.h>

/** This is information of a message fetched by MCONNTPListNewsgroupsOperation.*/

@interface MCONNTPGroupInfo : NSObject <NSCopying>

/** The name of the news group. */
@property (nonatomic, copy) NSString *name;

/** The number of messages in the news group. */
@property (nonatomic, assign) unsigned int messageCount;

@end

#endif
