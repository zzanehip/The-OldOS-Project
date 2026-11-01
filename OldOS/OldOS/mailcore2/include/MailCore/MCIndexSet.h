//
//  MCIndexSet.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/4/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCINDEXSET_H

#define MAILCORE_MCINDEXSET_H

#include <MailCore/MCObject.h>
#include <MailCore/MCRange.h>

#ifdef __cplusplus

#include <inttypes.h>

namespace mailcore {
    
    class MAILCORE_EXPORT IndexSet : public Object {
    public:
        IndexSet();
        virtual ~IndexSet();
        
        static IndexSet * indexSet();
        static IndexSet * indexSetWithRange(Range range);
        static IndexSet * indexSetWithIndex(uint64_t idx);
        
        virtual unsigned int count();
        virtual void addIndex(uint64_t idx);
        virtual void removeIndex(uint64_t idx);
        virtual bool containsIndex(uint64_t idx);
        
        virtual void addRange(Range range);
        virtual void removeRange(Range range);
        virtual void intersectsRange(Range range);
        
        virtual void addIndexSet(IndexSet * indexSet);
        virtual void removeIndexSet(IndexSet * indexSet);
        virtual void intersectsIndexSet(IndexSet * indexSet);
        
        virtual Range * allRanges();
        virtual unsigned int rangesCount();
        virtual void removeAllIndexes();
        
    public: // subclass behavior
        IndexSet(IndexSet * o);
        virtual String * description();
        virtual Object * copy();
        virtual HashMap * serializable();
        virtual void importSerializable(HashMap * serializable);
        virtual bool isEqual(Object * otherObject);

    private:
        Range * mRanges;
        unsigned int mCount;
        unsigned int mAllocated;
        void init();
        int rangeIndexForIndex(uint64_t idx);
        int rangeIndexForIndexWithBounds(uint64_t idx, unsigned int left, unsigned int right);
        void addRangeIndex(unsigned int rangeIndex);
        void removeRangeIndex(unsigned int rangeIndex, unsigned int count);
        int rightRangeIndexForIndex(uint64_t idx);
        int rightRangeIndexForIndexWithBounds(uint64_t idx, unsigned int left, unsigned int right);
        int leftRangeIndexForIndex(uint64_t idx);
        int leftRangeIndexForIndexWithBounds(uint64_t idx, unsigned int left, unsigned int right);
        void mergeRanges(unsigned int rangeIndex);
        void tryToMergeAdjacentRanges(unsigned int rangeIndex);
    };
    
}

#endif

#endif
