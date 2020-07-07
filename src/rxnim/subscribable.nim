import macros
import ./observable
import ./observer

type 
  NextHandle[T] = proc (value:T): void
  ErrorHandle = proc (error:ref Exception) : void
  CompletedHandle = proc ():void

  Subscriber*[T,S] = ref object of RootObj
    # destination: Subscriber[T,S]
    onNext: NextHandle[T]
    onError: ErrorHandle
    onCompleted:CompletedHandle
  
  Operator[T, R] = ref object of RootObj
    subscribe:proc (subscriber: Subscriber[T,R], source: any): Unsubscribable[Subscriber[T,R]]
  Subsribable*[T,S] = ref object of RootObj
    subscribers:seq[Subsribable[T,S]]
    source*:Subsribable[any,any]
    operator*: Operator[T, any]
    priSubscribe*:proc(subscriber: Subscriber[T,S]):void
  UnaryFunction[T, R] = proc (source:T): R
  ObservableOperatorFunction[T,R] = proc (source:Observable[T]): Observable[R] 
  SubsribableOperatorFunction[T,R] = proc (source:Subsribable[any,T]) :Subsribable[R,any]
  OperatorFunction[T, R] = SubsribableOperatorFunction[T,R] | ObservableOperatorFunction[T,R]
  Unsubscribable[T] = ref object of RootObj
    subscriber:T
    subsribable:T
    unsubscribe:proc(): void


proc subscribe*[T,R](self: Subsribable[T,R],subscriber: Subscriber[T,R]): Unsubscribable[Subscriber[T,R]] =
  new result
  self.subscribers.add subscriber
  result.subscriber = subscriber
  result.subscribable = self
  if not isNil(self.priSubscribe):
    self.priSubscribe(subscriber)


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
  
proc unSubscribe*[T](self:Unsubscribable[T]):void = 
  self.subscriber.dispose()
  let idx = self.subsribable.subscribers.find self.subscriber
  self.subsribable.subscribers.del idx

# proc newObservable*[T](subsribe:proc(subscriber:Subscriber[T]):void): Observable[T] =
#   result = new Observable[T](priSubscribe: subsribe)
#   # result.priSubscribe = subsribe
#   result.observers = newSeq[Observer[T]]()


# proc newObservable*[T](subsribe:proc(subscriber:Observer[T]):void):Observable[T] =
#   result = new Observable[T](priSubscribe: subsribe)
#   # result.priSubscribe = subsribe
#   result.observers = newSeq[Observer[T]]()

# proc lift[T,R](source:Observable[T],operator: Operator[T, R]): Observable[R] =
#     new result
#     result.source = source
#     result.operator = operator
type 
  MapOperator*[T,R] = ref object of Operator[T,R]
    project: proc(value: T, index: int):R
  MapSubscriber*[T, R] = ref object of Subscriber[T,R]
    count:int
    destination: Subscriber[T,R]
    project: proc(value: T, index: int):R


proc newMapSubscriber[T, R](destination: Subscriber[R,any],project: proc(value: T, index: int):R):Subscriber[T,R] = 
  result = new Subscriber[T,R](destination:destination,project:project)
  # result.destination = destination
  # result.project = project

proc next*[T,R](self:Subscriber[T,R],value:T):void = 
  self.onNext(value)

proc complete*[T,R](self:Subscriber[T,R]):void = discard
  # self.onNext(value)

proc error*[T,R](self:Subscriber[T,R],err:Exception):void = 
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

proc newMapOperator*[T,R](project: proc(value: T, index: int):R): MapOperator[T,R] =
  new result
  result.project = project

proc subscribe[T,R](self:MapOperator[T,R],subscriber: Subscriber[T,R], source: any) :any = 
  source.subscribe(newMapSubscriber(subscriber, self.project))

proc map*[T,R](project: proc(value: T, index: int):R): ObservableOperatorFunction[T, R] =
  result = proc (source: Observable[T]): Observable[R] =
    source.lift(newMapOperator(project))

proc lift*[T,R](source:Observable[T],operator: Operator[T, R]): Observable[R] =
    new result
    result.source = source
    result.operator = operator

macro pipe*(s:untyped,ops:varargs[untyped]):untyped = 
  result = newNimNode(nnkStmtList)
  var ob = s
  for op in ops:
    ob = newCall(op,ob)
    result.add ob

when isMainModule:
  var onNext = proc(value:string):void = 
    echo value
  var onError = proc(error:Exception):void = 
    echo $error
  var onCompleted = proc():void = 
    echo "done"
  var subsribe = proc(subscriber:Observer[int]):void =
    subscriber.next(1)
    subscriber.next(2)
    subscriber.next(3)
    subscriber.complete()
  var ob = newObservable(subsribe)
  var observer1 = newObserver(onNext, onError, onCompleted)
  var mapfunc = proc(value:int,index:int):string =
    $value
  var dispsable = ob.pipe(map(mapfunc)).subscribe( observer1 )