//
//  MCIndexSet.cpp
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/4/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCIndexSet.h"

#include "MCDefines.h"
#include "MCString.h"
#include "MCAssert.h"
#include "MCRange.h"
#include "MCLog.h"
#include "MCArray.h"
#include "MCHashMap.h"
#include "MCUtils.h"

using namespace mailcore;

void IndexSet::init()
{
    mRanges = NULL;
    mAllocated = 0;
    mCount = 0;
}

IndexSet::IndexSet()
{
    init();
}

IndexSet::IndexSet(IndexSet * o)
{
    init();
    mRanges = new Range[o->mAllocated];
    for(unsigned int i = 0 ; i < o->mCount ; i ++) {
        mRanges[i] = o->mRanges[i];
    }
    mAllocated = o->mAllocated;
    mCount = o->mCount;
}

IndexSet::~IndexSet()
{
    removeAllIndexes();
}

IndexSet * IndexSet::indexSet()
{
    IndexSet * result = new IndexSet();
    result->autorelease();
    return result;
}

IndexSet * IndexSet::indexSetWithRange(Range range)
{
    IndexSet * result = new IndexSet();
    result->autorelease();
    result->addRange(range);
    return result;
}

IndexSet * IndexSet::indexSetWithIndex(uint64_t idx)
{
    IndexSet * result = new IndexSet();
    result->autorelease();
    result->addIndex(idx);
    return result;
}

unsigned int IndexSet::count()
{
    unsigned int total = 0;
    for(unsigned int i = 0 ; i < mCount ; i ++) {
        total += mRanges[i].length + 1;
    }
    return total;
}

int IndexSet::rangeIndexForIndexWithBounds(uint64_t idx, unsigned int left, unsigned int right)
{
    unsigned int middle = (left + right) / 2;
    
    Range middleRange = mRanges[middle];
    
    if (left == right) {
        if ((idx >= RangeLeftBound(middleRange)) && (idx <= RangeRightBound(middleRange))) {
            return left;
        }
        return -1;
    }

    if ((idx >= RangeLeftBound(middleRange)) && (idx <= RangeRightBound(middleRange))) {
        return middle;
    }
    if (idx < middleRange.location) {
        return rangeIndexForIndexWithBounds(idx, left, middle);
    }
    else {
        return rangeIndexForIndexWithBounds(idx, middle + 1, right);
    }
}

int IndexSet::rangeIndexForIndex(uint64_t idx)
{
    if (mCount == 0)
        return -1;
    
    return rangeIndexForIndexWithBounds(idx, 0, mCount - 1);
}

int IndexSet::rightRangeIndexForIndexWithBounds(uint64_t idx, unsigned int left, unsigned int right)
{
    unsigned int middle = (left + right) / 2;
    
    Range middleRange = mRanges[middle];
    
    if (left == right) {
        if (idx > middleRange.location + middleRange.length) {
            return left + 1;
        }
        else {
            return left;
        }
    }
    
    if (idx < middleRange.location + middleRange.length) {
        return rightRangeIndexForIndexWithBounds(idx, left, middle);
    }
    else {
        return rightRangeIndexForIndexWithBounds(idx, middle + 1, right);
    }
}

int IndexSet::rightRangeIndexForIndex(uint64_t idx)
{
    if (mCount == 0)
        return 0;
    
    return rightRangeIndexForIndexWithBounds(idx, 0, mCount - 1);
}

int IndexSet::leftRangeIndexForIndexWithBounds(uint64_t idx, unsigned int left, unsigned int right)
{
    unsigned int middle = (left + right) / 2;
    
    Range middleRange = mRanges[middle];
    
    if (left == right) {
        if (idx <= RangeRightBound(middleRange)) {
            return left;
        }
        else {
            return left + 1;
        }
    }
    
    if (idx <= RangeRightBound(middleRange)) {
        return leftRangeIndexForIndexWithBounds(idx, left, middle);
    }
    else {
        return leftRangeIndexForIndexWithBounds(idx, middle + 1, right);
    }
}

int IndexSet::leftRangeIndexForIndex(uint64_t idx)
{
    if (mCount == 0)
        return 0;
    
    return leftRangeIndexForIndexWithBounds(idx, 0, mCount - 1);
}

void IndexSet::addRangeIndex(unsigned int rangeIndex)
{
    if (mAllocated < mCount + 1) {
        while (mAllocated < mCount + 1) {
            if (mAllocated == 0) {
                mAllocated = 4;
            }
            mAllocated *= 2;
        }
        
        Range * rangesReplacement = new Range[mAllocated];
        for(unsigned int i = 0 ; i < rangeIndex ; i ++) {
            rangesReplacement[i] = mRanges[i];
        }
        for(unsigned int i = rangeIndex ; i < mCount ; i ++) {
            rangesReplacement[i + 1] = mRanges[i];
        }
        mCount ++;
        rangesReplacement[rangeIndex].location = 0;
        rangesReplacement[rangeIndex].length = 0;
        delete [] mRanges;
        mRanges = rangesReplacement;
    }
    else {
        if (mCount > 0) {
            for(int i = mCount - 1 ; i >= (int) rangeIndex ; i --) {
                mRanges[i + 1] = mRanges[i];
            }
        }
        mCount ++;
        mRanges[rangeIndex].location = 0;
        mRanges[rangeIndex].length = 0;
    }
}

void IndexSet::addRange(Range range)
{
    int rangeIndex = leftRangeIndexForIndex(range.location);
    addRangeIndex(rangeIndex);
    mRanges[rangeIndex] = range;
    
    mergeRanges(rangeIndex);
    if (rangeIndex > 0) {
        tryToMergeAdjacentRanges(rangeIndex - 1);
    }
    if (rangeIndex < mCount - 1) {
        tryToMergeAdjacentRanges(rangeIndex);
    }
}

void IndexSet::tryToMergeAdjacentRanges(unsigned int rangeIndex)
{
    if (RangeRightBound(mRanges[rangeIndex]) == UINT64_MAX)
        return;
    
    if (RangeRightBound(mRanges[rangeIndex]) + 1 != mRanges[rangeIndex + 1].location) {
        return;
    }
    
    uint64_t right = RangeRightBound(mRanges[rangeIndex + 1]);
    removeRangeIndex(rangeIndex + 1, 1);
    mRanges[rangeIndex].length = right - mRanges[rangeIndex].location;
}

void IndexSet::mergeRanges(unsigned int rangeIndex)
{
    int right = rangeIndex;
    
    for(int i = rangeIndex ; i < mCount ; i ++) {
        if (RangeHasIntersection(mRanges[rangeIndex], mRanges[i])) {
            right = i;
        }
        else {
            break;
        }
    }
    
    if (right == rangeIndex)
        return;
    
    IndexSet * indexSet = RangeUnion(mRanges[rangeIndex], mRanges[right]);
    MCAssert(indexSet->rangesCount() > 0);
    Range range = indexSet->allRanges()[0];
    removeRangeIndex(rangeIndex + 1, right - rangeIndex);
    mRanges[rangeIndex] = range;
}

void IndexSet::addIndex(uint64_t idx)
{
    addRange(RangeMake(idx, 0));
}

void IndexSet::removeRangeIndex(unsigned int rangeIndex, unsigned int count)
{
    for(unsigned int i = rangeIndex + count ; i < mCount ; i ++) {
        mRanges[i - count] = mRanges[i];
    }
    mCount -= count;
}

void IndexSet::removeRange(Range range)
{
    int left = -1;
    int right = -1;
    int leftRangeIndex = leftRangeIndexForIndex(range.location);
    if (leftRangeIndex >= mCount) {
        leftRangeIndex = mCount - 1;
    }
    for(int i = leftRangeIndex ; i < mCount ; i ++) {
        if (RangeHasIntersection(mRanges[i], range)) {
            IndexSet * indexSet = RangeRemoveRange(mRanges[i], range);
            if (indexSet->rangesCount() == 0) {
                if (left == -1) {
                    left = i;
                }
                right = i;
                mRanges[i] = RangeEmpty;
            }
            else if (indexSet->rangesCount() == 1) {
                mRanges[i] = indexSet->allRanges()[0];
            }
            else {
                MCAssert(indexSet->rangesCount() == 2);
                addRangeIndex(i);
                mRanges[i] = indexSet->allRanges()[0];
                mRanges[i + 1] = indexSet->allRanges()[1];
            }
        }
        else {
            break;
        }
    }
    
    if (left != -1) {
        removeRangeIndex(left, right - left + 1);
    }
}

void IndexSet::removeIndex(uint64_t idx)
{
    removeRange(RangeMake(idx, 0));
}

bool IndexSet::containsIndex(uint64_t idx)
{
    int rangeIndex = rangeIndexForIndex(idx);
    return rangeIndex != -1;
}

unsigned int IndexSet::rangesCount()
{
    return mCount;
}

Range * IndexSet::allRanges()
{
    return mRanges;
}

void IndexSet::removeAllIndexes()
{
    delete[] mRanges;
    mRanges = NULL;
    mAllocated = 0;
    mCount = 0;
}

String * IndexSet::description()
{
    String * result = String::string();
    for(unsigned int i = 0 ; i < mCount ; i ++) {
        if (i != 0) {
            result->appendUTF8Format(",");
        }
        if (mRanges[i].length == 0) {
            result->appendUTF8Format("%llu",
                                     (unsigned long long) mRanges[i].location);
        }
        else {
            result->appendUTF8Format("%llu-%llu",
                                     (unsigned long long) mRanges[i].location,
                                     (unsigned long long) (mRanges[i].location + mRanges[i].length));
        }
    }
    return result;
}

Object * IndexSet::copy()
{
    return new IndexSet(this);
}

void IndexSet::intersectsRange(Range range)
{
    uint64_t right = RangeRightBound(range);
    if (right == UINT64_MAX) {
        removeRange(RangeMake(0, range.location - 1));
    }
    else {
        removeRange(RangeMake(0, range.location - 1));
        removeRange(RangeMake(right + 1, UINT64_MAX));
    }
}


HashMap * IndexSet::serializable()
{
    HashMap * result = Object::serializable();
    Array * ranges = Array::array();
    for(unsigned int i = 0 ; i < mCount ; i ++) {
        ranges->addObject(RangeToString(mRanges[i]));
    }
    result->setObjectForKey(MCSTR("ranges"), ranges);
    return result;
}

void IndexSet::importSerializable(HashMap * serializable)
{
    Array * ranges = (Array *) serializable->objectForKey(MCSTR("ranges"));
    for(unsigned int i = 0 ; i < ranges->count() ; i ++) {
        String * rangeStr = (String *) ranges->objectAtIndex(i);
        addRange(RangeFromString(rangeStr));
    }
}

bool IndexSet::isEqual(Object * otherObject)
{
    IndexSet * otherIndexSet = (IndexSet *) otherObject;
    if (mCount != otherIndexSet->mCount) {
        return false;
    }
    for(unsigned int i = 0 ; i < mCount ; i ++) {
        if ((mRanges[i].location != otherIndexSet->mRanges[i].location) ||
            (mRanges[i].length != otherIndexSet->mRanges[i].length)) {
            return false;
        }
    }
    return true;
}

void IndexSet::addIndexSet(IndexSet * indexSet)
{
    for(unsigned int i = 0 ; i < indexSet->rangesCount() ; i ++) {
        addRange(indexSet->allRanges()[i]);
    }
}

void IndexSet::removeIndexSet(IndexSet * indexSet)
{
    for(unsigned int i = 0 ; i < indexSet->rangesCount() ; i ++) {
        removeRange(indexSet->allRanges()[i]);
    }
}

void IndexSet::intersectsIndexSet(IndexSet * indexSet)
{
    IndexSet * result = new IndexSet();
    for(unsigned int i = 0 ; i < indexSet->rangesCount() ; i ++) {
        IndexSet * rangeIntersect = (IndexSet *) copy();
        rangeIntersect->intersectsRange(indexSet->allRanges()[i]);
        result->addIndexSet(rangeIntersect);
        rangeIntersect->release();
    }
    removeAllIndexes();
    addIndexSet(result);
    result->release();
}

static void * createObject()
{
    return new IndexSet();
}

INITIALIZE(IndexSet)
{
    Object::registerObjectConstructor("mailcore::IndexSet", &createObject);
}

/*
 
Unit test:

String * uidsStr = MCSTR("129597-129662,129664,129667-129671,129673-129674,129678-129694,129696-129804");
String * cachedUidsStr = MCSTR("129755-129804");
IndexSet * uids = NULL;
IndexSet * cachedUids = NULL;

{
    IndexSet * result = new IndexSet();
    Array * array = uidsStr->componentsSeparatedByString(MCSTR(","));
    mc_foreacharray(String, rangeStr, array) {
        Array * rangeArray = rangeStr->componentsSeparatedByString(MCSTR("-"));
        if (rangeArray->count() == 2) {
            int left = ((String *) rangeArray->objectAtIndex(0))->intValue();
            int right = ((String *) rangeArray->objectAtIndex(1))->intValue();
            int length = right - left;
            result->addRange(RangeMake(left, length));
        }
        else {
            result->addIndex(rangeStr->intValue());
        }
    }
    //fprintf(stderr, "%s\n", MCUTF8DESC(result));
    uids = result;
}
{
    IndexSet * result = new IndexSet();
    Array * array = cachedUidsStr->componentsSeparatedByString(MCSTR(","));
    mc_foreacharray(String, rangeStr, array) {
        Array * rangeArray = rangeStr->componentsSeparatedByString(MCSTR("-"));
        if (rangeArray->count() == 2) {
            int left = ((String *) rangeArray->objectAtIndex(0))->intValue();
            int right = ((String *) rangeArray->objectAtIndex(1))->intValue();
            int length = right - left;
            result->addRange(RangeMake(left, length));
        }
        else {
            result->addIndex(rangeStr->intValue());
        }
    }
    cachedUids = result;
}
fprintf(stderr, "|%s|\n", MCUTF8DESC(uids));
uids->removeIndexSet(cachedUids);
fprintf(stderr, "|%s|\n", MCUTF8DESC(uids));
*/
