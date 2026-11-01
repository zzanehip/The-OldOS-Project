//
//  MCHTMLRendererIMAPDataCallback.cc
//  mailcore2
//
//  Created by Paul Young on 06/07/2013.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCHTMLRendererIMAPDataCallback.h"

using namespace mailcore;

HTMLRendererIMAPDataCallback::HTMLRendererIMAPDataCallback(IMAPSession * session, uint32_t uid)
{
    mSession = session;
    mUid = uid;
    mError = ErrorNone;
}

Data * HTMLRendererIMAPDataCallback::dataForIMAPPart(String * folder, IMAPPart * part)
{
    return mSession->fetchMessageAttachmentByUID(folder, mUid, part->partID(), part->encoding(), NULL, &mError);
}

ErrorCode  HTMLRendererIMAPDataCallback::error()
{
    return mError;
}