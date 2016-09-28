//
//  The MIT License (MIT)
//
//  Copyright (c) 2016 Srdan Rasic (@srdanrasic)
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

import ReactiveKit

public enum ObservableDictionaryEventKind<Key: Hashable, Value> {
  case initial
  case inserts([DictionaryIndex<Key, Value>])
  case deletes([DictionaryIndex<Key, Value>])
  case updates([DictionaryIndex<Key, Value>])
  case beginBatchEditing
  case endBatchEditing
}

public struct ObservableDictionaryEvent<Key: Hashable, Value> {
  public let kind: ObservableDictionaryEventKind<Key, Value>
  public let source: Dictionary<Key, Value>
}

open class ObservableDictionary<Key: Hashable, Value>: Collection {

  fileprivate var dictionary: Dictionary<Key, Value>
  fileprivate let subject = PublishSubject<ObservableDictionaryEvent<Key, Value>, NoError>()
  fileprivate let lock = NSRecursiveLock(name: "ObservableDictionary")

  public init(_ dictionary: Dictionary<Key, Value>) {
    self.dictionary = dictionary
  }

  open func makeIterator() -> Dictionary<Key, Value>.Iterator {
    return dictionary.makeIterator()
  }

  open var underestimatedCount: Int {
    return dictionary.underestimatedCount
  }

  open var startIndex: DictionaryIndex<Key, Value> {
    return dictionary.startIndex
  }

  open var endIndex: DictionaryIndex<Key, Value> {
    return dictionary.endIndex
  }

  open func index(after i: DictionaryIndex<Key, Value>) -> DictionaryIndex<Key, Value> {
    return dictionary.index(after: i)
  }

  open var isEmpty: Bool {
    return dictionary.isEmpty
  }

  open var count: Int {
    return dictionary.count
  }

  open subscript(position: DictionaryIndex<Key, Value>) -> Dictionary<Key, Value>.Iterator.Element {
    get {
      return dictionary[position]
    }
  }

  open subscript(key: Key) -> Value? {
    get {
      return dictionary[key]
    }
  }

  open func observe(with observer: @escaping (Event<ObservableDictionaryEvent<Key, Value>, NoError>) -> Void) -> Disposable {
    observer(.next(ObservableDictionaryEvent(kind: .initial, source: dictionary)))
    return subject.observe(with: observer)
  }
}

open class MutableObservableDictionary<Key: Hashable, Value>: ObservableDictionary<Key, Value> {

  open override subscript (key: Key) -> Value? {
    get {
      return dictionary[key]
    }
    set {
      if let value = newValue {
        _ = updateValue(value, forKey: key)
      } else {
        _ = removeValue(forKey: key)
      }
    }
  }

  /// Update (or insert) value in the dictionary.
  open func updateValue(_ value: Value, forKey key: Key) -> Value? {
    if let index = dictionary.index(forKey: key) {
      let old = dictionary.updateValue(value, forKey: key)
      subject.next(ObservableDictionaryEvent(kind: .updates([index]), source: dictionary))
      return old
    } else {
      _ = dictionary.updateValue(value, forKey: key)
      subject.next(ObservableDictionaryEvent(kind: .inserts([dictionary.index(forKey: key)!]), source: dictionary))
      return nil
    }
  }

  /// Remove value from the dictionary.
  open func removeValue(forKey key: Key) -> Value? {
    if let index = dictionary.index(forKey: key) {
      let (_, old) = dictionary.remove(at: index)
      subject.next(ObservableDictionaryEvent(kind: .deletes([index]), source: dictionary))
      return old
    } else {
      return nil
    }
  }

  /// Perform batched updates on the dictionary.
  open func batchUpdate(_ update: @escaping (MutableObservableDictionary<Key, Value>) -> Void) {
    lock.atomic {
      subject.next(ObservableDictionaryEvent(kind: .beginBatchEditing, source: dictionary))
      update(self)
      subject.next(ObservableDictionaryEvent(kind: .endBatchEditing, source: dictionary))
    }
  }

  /// Change the underlying value withouth notifying the observers.
  open func silentUpdate(_ update: @escaping (inout Dictionary<Key, Value>) -> Void) {
    lock.atomic {
      update(&dictionary)
    }
  }
}
