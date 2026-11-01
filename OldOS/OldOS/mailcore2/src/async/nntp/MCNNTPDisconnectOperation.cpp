//
//  MCNNTPDisconnectOperation.cpp
//  mailcore2
//
//  Created by Robert Widmann on 8/13/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#include "MCNNTPDisconnectOperation.h"

#include "MCNNTPAsyncSession.h"
#include "MCNNTPSession.h"

using namespace mailcore;

NNTPDisconnectOperation::NNTPDisconnectOperation()
{
}

NNTPDisconnectOperation::~NNTPDisconnectOperation()
{
}

void NNTPDisconnectOperation::main()
{
    ErrorCode error;
    
    session()->session()->checkAccount(&error);
    setError(error);
}
