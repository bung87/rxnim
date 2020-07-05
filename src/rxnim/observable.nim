import ./observer

type 
  Disposable*[T] = ref object of RootObj
    observer:Observer[T]
    observable:Observable[T]
  Observable*[T] = ref object of RootObj
    observers: seq[Observer[T]]
    # source:Observable[T]
    # operator:Operator[T,R]
    priSubscribe:proc(observer: Observer[T]):void
  Subscribale*[T,R] = ref object of RootObj
    observers: seq[Observer[T]]
    source:Observable[T]
    operator:Operator[T,R]
    priSubscribe:proc(observer: Observer[T]):void
  Operator*[T,R] = object of RootObj

proc add*[T,R](self:Disposable[T] ,t:Disposable[R]):Disposable[R] = 
  self.observable.observers.add t.observers
  t.observer.priSubscribe = self.observer.priSubscribe

proc subscribe*[T](self: Observable[T],observer: Observer[T]): Disposable[T] =
  new result
  self.observers.add observer
  result.observer = observer
  result.observable = self
  if not isNil(self.priSubscribe):
    self.priSubscribe(observer)
  if not isNil(self.operator):
    var sink = newObserver[R](observer.onNext, observer.onError, observer.onCompleted)
    sink.add(self.operator.call(sink, self))

proc unSubscribe*(self:Disposable):void = 
  self.observer.dispose()
  let idx = self.observable.observers.find self.observer
  self.observable.observers.del idx

proc newObservable*[T](): Observable[T] =
  result = new Observable[T]
  result.observers = newSeq[Observer[T]]()

proc newObservable*[T](subsribe:proc(subscriber:Observer[T]):void):Observable[T] =
  result = new Observable[T]
  result.priSubscribe = subsribe
  result.observers = newSeq[Observer[T]]()

type 
  OperatorFunction[T, R] = proc (source: Observable[T]): Observable[R]

proc lift*[T,R](source:Observable[T],operator:Operator[T,R]):Subscribale[T,R] =
  result = Subscribale[T,R]()
  result.priSubscribe = source.priSubscribe
  result.source = source
  result.observers = newSeq[Observer[R]]()
  result.operator = operator

proc pipe*[T,R](self:Observable[T], operators:varargs[OperatorFunction[T,R]]):Subscribale[T,R] =
  result = proc(input:T): R =
    result = input
    for operator in operators:
      # result = self.operator.call(sink, self)
      var sink = newObserver[R](self.onNext, self.onError, self.onCompleted)
      sink.add(self.operator.call(sink, self))
  # subscribe(observerOrNext?: PartialObserver<T> | ((value: T) => void) | null,
  #           error?: ((error: any) => void) | null,
  #           complete?: (() => void) | null): Subscription {

  #   const { operator } = this;
  #   const sink = toSubscriber(observerOrNext, error, complete);

  #   if (operator) {
  #     sink.add(operator.call(sink, this.source));
  #   } else {
  #     sink.add(
  #       this.source || (config.useDeprecatedSynchronousErrorHandling && !sink.syncErrorThrowable) ?
  #       this._subscribe(sink) :
  #       this._trySubscribe(sink)
  #     );
  #   }

  #   if (config.useDeprecatedSynchronousErrorHandling) {
  #     if (sink.syncErrorThrowable) {
  #       sink.syncErrorThrowable = false;
  #       if (sink.syncErrorThrown) {
  #         throw sink.syncErrorValue;
  #       }
  #     }
  #   }

  #   return sink;
  # }