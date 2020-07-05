import ./observer

type 
  Disposable*[T] = ref object of RootObj
    observer:Observer[T]
    observable:Observable[T]
  Observable*[T] = ref object of RootObj
    observers: seq[Observer[T]]
    source*:Observable[any]
    operator*: Operator[T, any]
    priSubscribe*:proc(subscriber: Subscriber[T]):void
  UnaryFunction[T, R] = proc (source:T): R
  OperatorFunction[T, R] = proc (source:Observable[T]) :Observable[R]
  Subscriber[T] = ref object of RootObj
    # destination: Observer[any] #| Subscriber[any]
  Unsubscribable = ref object of RootObj
    unsubscribe:proc(): void

  TeardownLogic = Unsubscribable #| Function | void
  Operator[T, R] = ref object of RootObj
    call:proc (subscriber: Subscriber[R], source: any): TeardownLogic


proc subscribe*[T](self: Observable[T],observer: Observer[T]): Disposable[T] =
  new result
  self.observers.add observer
  result.observer = observer
  result.observable = self
  if not isNil(self.priSubscribe):
    self.priSubscribe(observer)

template reduce(eles:untyped,fn: untyped,initial:untyped):untyped =
  for ele in eles:
    result = fn(initial,ele)

proc pipeFromArray[T, R](fns: varargs[UnaryFunction[T, R]]): UnaryFunction[T, R] =
  result = proc (input: T): R =
    var fn = proc (prev: any, fn: UnaryFunction[T, R]) = fn.call(prev)
    return fns.reduce(fn, input )

proc pipe[T](self: Observable[T],operations: varargs[OperatorFunction[any,any]]): Observable[any] =
  if (operations.len == 0):
    return self
  return pipeFromArray(operations)(self)
  
proc unSubscribe*(self:Disposable):void = 
  self.observer.dispose()
  let idx = self.observable.observers.find self.observer
  self.observable.observers.del idx

proc newObservable*[T](subsribe:proc(subscriber:Subscriber[T]):void): Observable[T] =
  result = new Observable[T](priSubscribe: subsribe)
  # result.priSubscribe = subsribe
  result.observers = newSeq[Observer[T]]()


proc newObservable*[T](subsribe:proc(subscriber:Observer[T]):void):Observable[T] =
  result = new Observable[T](priSubscribe: subsribe)
  # result.priSubscribe = subsribe
  result.observers = newSeq[Observer[T]]()

proc lift[T,R](source:Observable[T],operator: Operator[T, R]): Observable[R] =
    new result
    result.source = source
    result.operator = operator
  
type 
  MapOperator[T,R] = ref object of RootObj
    project: proc(value: T, index: int):R
  MapSubscriber[T, R] = ref object of Subscriber[T]
    count:int
    destination: Observer[R] | Subscriber[R]
    project: proc(value: T, index: int):R


proc newMapSubscriber[T, R](destination: Subscriber[R],project: proc(value: T, index: int):R):Subscriber[T] = 
  result = new Subscriber[T](destination:destination,project:project)
  # result.destination = destination
  # result.project = project


proc next*[T](self:Subscriber[T],value:T):void = discard
  # self.onNext(value)

proc complete*[T](self:Subscriber[T]):void = discard
  # self.onNext(value)

proc error*[T](self:Subscriber[T],err:Exception):void = 
  self.onError(err)

proc next[T,R](self:MapSubscriber[T, R],value:T):void = 
  var result: R
  try:
    result = self.project(value, self.count)
  except Exception as e:
    self.destination.error(e)
    return
  self.destination.next(result)
  self.count += 1

proc newMapOperator[T,R](project: proc(value: T, index: int):R):MapOperator[T,R] =
  result = new MapOperator[T,R](project:project)

proc call[T,R](self:MapOperator[T,R],subscriber: Subscriber[R], source: any) :any = 
  source.subscribe(newMapSubscriber(subscriber, self.project))

proc map[T,R](project: proc(value: T, index: int):R): OperatorFunction[T, R] =
  result = proc (source: Observable[T]): Observable[R] =
    source.lift(newMapOperator(project))


when isMainModule:
  var onNext = proc(value:string):void = 
    echo value
  var onError = proc(error:ref Exception):void = 
    echo $error.msg
  var onCompleted = proc():void = 
    echo "done"
  var subsribe = proc(subscriber:Subscriber[int]):void =
    subscriber.next(1)
    subscriber.next(2)
    subscriber.next(3)
    subscriber.complete()
  var observable = newObservable[int](subsribe)
  var observer1 = newObserver(onNext, onError, onCompleted)
  var mapfunc = proc(value:int):string =
    $value
  var dispsable = observable.pipe(map(mapfunc)).subscribe( observer1 )