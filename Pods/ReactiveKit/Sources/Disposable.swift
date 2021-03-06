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

import Foundation

/// Objects conforming to this protocol dispose (cancel) signals and operations.
public protocol Disposable {

  /// Dispose the signal or operation.
  func dispose()

  /// Returns `true` is already disposed.
  var isDisposed: Bool { get }
}

/// A disposable that cannot be disposed.
public struct NonDisposable: Disposable {

  public static let instance = NonDisposable()

  fileprivate init() {}

  public func dispose() {
  }

  public var isDisposed: Bool {
    return false
  }
}

/// A disposable that just encapsulates disposed state.
public final class SimpleDisposable: Disposable {
  public fileprivate(set) var isDisposed: Bool = false

  public func dispose() {
    isDisposed = true
  }

  public init() {}
}

/// A disposable that executes the given block upon disposing.
public final class BlockDisposable: Disposable {

  public var isDisposed: Bool {
    return handler == nil
  }

  fileprivate var handler: (() -> ())?
  fileprivate let lock = NSRecursiveLock(name: "ReactiveKit.BlockDisposable")

  public init(_ handler: @escaping () -> ()) {
    self.handler = handler
  }

  public func dispose() {
    lock.atomic {
      handler?()
      handler = nil
    }
  }
}

/// A disposable that disposes itself upon deallocation.
open class DeinitDisposable: Disposable {

  open var otherDisposable: Disposable? = nil

  open var isDisposed: Bool {
    return otherDisposable == nil
  }

  public init(disposable: Disposable) {
    otherDisposable = disposable
  }

  open func dispose() {
    otherDisposable?.dispose()
  }

  deinit {
    otherDisposable?.dispose()
  }
}

/// A disposable that disposes a collection of disposables upon disposing.
public final class CompositeDisposable: Disposable {

  public fileprivate(set) var isDisposed: Bool = false
  fileprivate var disposables: [Disposable] = []
  fileprivate let lock = NSRecursiveLock(name: "ReactiveKit.CompositeDisposable")

  public convenience init() {
    self.init([])
  }

  public init(_ disposables: [Disposable]) {
    self.disposables = disposables
  }

  public func add(_ disposable: Disposable) {
    lock.atomic {
      if isDisposed {
        disposable.dispose()
      } else {
        disposables.append(disposable)
        self.disposables = disposables.filter { $0.isDisposed == false }
      }
    }
  }

  public func dispose() {
    lock.atomic {
      isDisposed = true
      disposables.forEach { $0.dispose() }
      disposables.removeAll()
    }
  }
}

public func += (left: CompositeDisposable, right: Disposable) {
  left.add(right)
}

/// A disposable container that will dispose a collection of disposables upon deinit.
public final class DisposeBag: Disposable {
  fileprivate var disposables: [Disposable] = []
  fileprivate let subject = _ReplayOneSubject<Void, NoError>()

  /// This will return true whenever the bag is empty.
  public var isDisposed: Bool {
    return disposables.count == 0
  }

  public init() {
  }

  /// Adds the given disposable to the bag.
  /// Disposable will be disposed when the bag is deinitialized.
  public func add(_ disposable: Disposable) {
    disposables.append(disposable)
  }

  /// Disposes all disposables that are currenty in the bag.
  public func dispose() {
    disposables.forEach { $0.dispose() }
    disposables.removeAll()
  }
  
  public var deallocated: Signal1<Void> {
    return subject.toSignal()
  }

  deinit {
    dispose()
    subject.completed()
  }
}

public extension Disposable {
  public func disposeIn(_ disposeBag: DisposeBag) {
    disposeBag.add(self)
  }
}

/// A disposable that disposes other disposable.
public final class SerialDisposable: Disposable {

  public fileprivate(set) var isDisposed: Bool = false
  fileprivate let lock = NSRecursiveLock(name: "ReactiveKit.SerialDisposable")

  /// Will dispose other disposable immediately if self is already disposed.
  public var otherDisposable: Disposable? {
    didSet {
      lock.atomic {
        if isDisposed {
          otherDisposable?.dispose()
        }
      }
    }
  }

  public init(otherDisposable: Disposable?) {
    self.otherDisposable = otherDisposable
  }

  public func dispose() {
    lock.atomic {
      if !isDisposed {
        isDisposed = true
        otherDisposable?.dispose()
      }
    }
  }
}

/// A type that provides dispose bag.
public protocol DisposeBagProvider: class {
  var disposeBag: DisposeBag { get }
}
