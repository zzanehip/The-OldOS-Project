//
//  IMAPFetchNamespaceOperation.cc
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/12/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCIMAPFetchNamespaceOperation.h"

#include "MCIMAPSession.h"
#include "MCIMAPAsyncConnection.h"

using namespace mailcore;

IMAPFetchNamespaceOperation::IMAPFetchNamespaceOperation()
{
    mNamespaces = NULL;
}

IMAPFetchNamespaceOperation::~IMAPFetchNamespaceOperation()
{
    MC_SAFE_RELEASE(mNamespaces);
}

void IMAPFetchNamespaceOperation::main()
{
    ErrorCode error;
    mNamespaces = session()->session()->fetchNamespace(&error);
    setError(error);
    MC_SAFE_RETAIN(mNamespaces);
}

HashMap * IMAPFetchNamespaceOperation::namespaces()
{
    return mNamespaces;
}

