//
//  MCNNTPCheckAccountOperation.cpp
//  mailcore2
//
//  Created by Robert Widmann on 8/13/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#include "MCNNTPCheckAccountOperation.h"

#include "MCNNTPAsyncSession.h"
#include "MCNNTPSession.h"

using namespace mailcore;

NNTPCheckAccountOperation::NNTPCheckAccountOperation()
{
}

NNTPCheckAccountOperation::~NNTPCheckAccountOperation()
{
}

void NNTPCheckAccountOperation::main()
{
    ErrorCode error;
    
    session()->session()->checkAccount(&error);
    setError(error);
}
