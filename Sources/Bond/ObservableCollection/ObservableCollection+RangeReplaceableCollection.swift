//
//  The MIT License (MIT)
//
//  Copyright (c) 2018 DeclarativeHub/Bond
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

extension MutableObservableCollection where UnderlyingCollection: RangeReplaceableCollection {

    /// Append `newElement` at the end of the collection.
    public func append(_ newElement: UnderlyingCollection.Element) {
        descriptiveUpdate { (collection) -> CollectionDiff<UnderlyingCollection.Index> in
            collection.append(newElement)
            return CollectionDiff(inserts: [collection.index(collection.endIndex, offsetBy: -1)], areIndicesPresorted: true)
        }
    }

    /// Insert `newElement` at index `i`.
    public func insert(_ newElement: UnderlyingCollection.Element, at index: UnderlyingCollection.Index) {
        descriptiveUpdate { (collection) -> CollectionDiff<UnderlyingCollection.Index> in
            collection.insert(newElement, at: index)
            return CollectionDiff(inserts: [index], areIndicesPresorted: true)
        }
    }

    /// Insert elements `newElements` at index `i`.
    public func insert(contentsOf newElements: [UnderlyingCollection.Element], at index: UnderlyingCollection.Index) {
        descriptiveUpdate { (collection) -> CollectionDiff<UnderlyingCollection.Index> in
            collection.insert(contentsOf: newElements, at: index)
            let endIndex = collection.index(index, offsetBy: newElements.count)
            return CollectionDiff(inserts: collection.indices[index..<endIndex].map { $0 }, areIndicesPresorted: true)
        }
    }

    /// Move the element at index `i` to index `toIndex`.
    public func move(from fromIndex: UnderlyingCollection.Index, to toIndex: UnderlyingCollection.Index) {
        descriptiveUpdate { (collection) -> CollectionDiff<UnderlyingCollection.Index> in
            collection.move(from: fromIndex, to: toIndex)
            return CollectionDiff(moves: [(from: fromIndex, to: toIndex)], areIndicesPresorted: true)
        }
    }

    /// Remove and return the element at index i.
    @discardableResult
    public func remove(at index: UnderlyingCollection.Index) -> UnderlyingCollection.Element {
        return descriptiveUpdate { (collection) -> (CollectionDiff<UnderlyingCollection.Index>, UnderlyingCollection.Element) in
            let element = collection.remove(at: index)
            return (CollectionDiff(deletes: [index], areIndicesPresorted: true), element)
        }
    }

    /// Remove an element from the end of the collection in O(1).
    @discardableResult
    public func removeLast() -> UnderlyingCollection.Element {
        return descriptiveUpdate { (collection) -> (CollectionDiff<UnderlyingCollection.Index>, UnderlyingCollection.Element) in
            let index = collection.index(collection.endIndex, offsetBy: -1)
            let element = collection.remove(at: index)
            return (CollectionDiff(deletes: [index], areIndicesPresorted: true), element)
        }
    }

    /// Remove all elements from the collection.
    public func removeAll() {
        descriptiveUpdate { (collection) -> CollectionDiff<UnderlyingCollection.Index> in
            let deletes = collection.indices.reversed().map { $0 }
            collection.removeAll(keepingCapacity: false)
            return CollectionDiff(deletes: deletes, areIndicesPresorted: true)
        }
    }
}

extension MutableObservableCollection where UnderlyingCollection: RangeReplaceableCollection, UnderlyingCollection.Index: Strideable, UnderlyingCollection.Index.Stride == Int {

    public func move(from fromIndices: [UnderlyingCollection.Index], to toIndex: UnderlyingCollection.Index) {
        descriptiveUpdate { (collection) -> CollectionDiff<UnderlyingCollection.Index> in
            collection.move(from: fromIndices, to: toIndex)
            let moves = fromIndices.enumerated().map {
                (from: $0.element, to: toIndex.advanced(by: $0.offset))
            }
            return CollectionDiff(moves: moves, areIndicesPresorted: true)
        }
    }
}

extension MutableObservableCollection where UnderlyingCollection.Index: Strideable {

    /// Perform batched updates on the collection. Emits an event with the combined diff of all made changes.
    /// Diffs are combined by shifting elements when needed and annihilating confling operations like I(2) -> D(2).
    public func batchUpdate(_ update: (MutableObservableCollection<UnderlyingCollection>) -> Void) {
        batchUpdate(update, mergeDiffs: { _, diffs in
            CollectionDiff<UnderlyingCollection.Index>(merging: diffs, strider: StridableIndexStrider())
        })
    }
}

extension RangeReplaceableCollection {

    public mutating func move(from fromIndex: Index, to toIndex: Index) {
        let item = remove(at: fromIndex)
        insert(item, at: toIndex)
    }
}

extension RangeReplaceableCollection where Index: Strideable, Index.Stride == Int {

    public mutating func move(from fromIndices: [Index], to toIndex: Index) {
        let items = fromIndices.map { self[$0] }
        for index in fromIndices.sorted().reversed() {
            remove(at: index)
        }
        insert(contentsOf: items, at: toIndex)
    }
}
