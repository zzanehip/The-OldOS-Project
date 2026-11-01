//
//  Header.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 6/22/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCOIMAPBASEOPERATION_PRIVATE_H

#define MAILCORE_MCOIMAPBASEOPERATION_PRIVATE_H

@class MCOIMAPSession;

@interface MCOIMAPBaseOperation (Private)

@property (nonatomic, retain) MCOIMAPSession * session;

@end

#endif
