type 
  NextHandle[T] = proc (value:T): void
  ErrorHandle = proc (error:Exception) : void
  CompletedHandle = proc ():void
  Observer*[T] = ref object of RootObj
    onNext: NextHandle[T]
    onError: ErrorHandle
    onCompleted:CompletedHandle

proc dispose*[T](self:Observer[T]):void =
  self.onNext = proc (value:T): void = discard
  self.onError = proc (error:Exception) : void = discard
  self.onCompleted = proc ():void = discard

proc next*[T](self:Observer[T],value:T):void = 
  self.onNext(value)

proc complete*[T](self:Observer[T]):void =
  self.onCompleted()

proc newObserver*[T](onNext:NextHandle[T],onError: ErrorHandle,onCompleted:CompletedHandle):Observer[T] = 
  new result
  result.onNext = onNext
  result.onError = onError
  result.onCompleted = onCompleted