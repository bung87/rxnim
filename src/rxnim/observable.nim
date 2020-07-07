import ./observer

type 
  Disposable*[T] = ref object of RootObj
    observer:Observer[T]
    observable:Observable[T]
  Observable*[T] = ref object of RootObj
    observers: seq[Observer[T]]
    priSubscribe*:proc(subscriber: Observer[T]):void

proc subscribe*[T](self: Observable[T],observer: Observer[T]): Disposable[T] =
  new result
  self.observers.add observer
  result.observer = observer
  result.observable = self

# template reduce(eles:untyped,fn: untyped,initial:untyped):untyped =
#   for ele in eles:
#     result = fn(initial,ele)

# proc pipeFromArray[T, R](fns: varargs[UnaryFunction[T, R]]): UnaryFunction[T, R] =
#   result = proc (input: T): R =
#     var fn = proc (prev: any, fn: UnaryFunction[T, R]) = fn.call(prev)
#     return fns.reduce(fn, input )

# proc pipe[T](self: Observable[T],operations: varargs[OperatorFunction[any,any]]): Observable[any] =
#   if (operations.len == 0):
#     return self
#   return pipeFromArray(operations)(self)
  
proc unSubscribe*(self:Disposable):void = 
  self.observer.dispose()
  let idx = self.observable.observers.find self.observer
  self.observable.observers.del idx

proc newObservable*[T](): Observable[T] =
  result = new Observable[T]
  result.observers = newSeq[Observer[T]]()

proc newObservable*[T](subsribe:proc(subscriber:Observer[T]):void):Observable[T] =
  new result
  result.priSubscribe = subsribe
  result.observers = newSeq[Observer[T]]()