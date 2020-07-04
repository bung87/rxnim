import ./observer

type 
  Disposable*[T] = ref object of RootObj
    observer:Observer[T]
    observable:Observable[T]
  Observable*[T] = ref object of RootObj
    observers: seq[Observer[T]]

proc subscribe*[T](self: Observable[T],observer: Observer[T]): Disposable[T] =
  new result
  self.observers.add observer
  result.observer = observer
  result.observable = self

proc unSubscribe*(self:Disposable):void = 
  self.observer.dispose()
  let idx = self.observable.observers.find self.observer
  self.observable.observers.del idx

proc newObservable*[T](): Observable[T] =
  result = new Observable[T]
  result.observers = newSeq[Observer[T]]()