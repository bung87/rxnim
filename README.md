# rxnim  

Reactive programing in Nim

## Usage  

``` nim

  var onNext = proc(value:int):void = 
    check value == 1
    echo "from1"
  var onError = proc(error:Exception):void = 
    echo $error
  var onCompleted = proc():void = 
    echo "done"
  var observer = newObserver[int](onNext, onError, onCompleted)
  var observable = newObservable[int]()
  var dispsable = observable.subscribe( observer )
  observer.next(1)
  dispsable.unSubscribe()
  observer.next(2)

  ```