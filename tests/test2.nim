import unittest
import rxnim

test "can have multiple subscribers":
  var i = 1
  var onNext = proc(value:int):void = 
    check i == value
    i += 1
    if i > 3:
      i = 1
  
  var onError = proc(error:Exception):void = 
    echo $error
  var onCompleted = proc():void = 
    echo "done"
  var subsribe = proc(subscriber:Observer[int]):void =
    subscriber.next(1)
    subscriber.next(2)
    subscriber.next(3)
    subscriber.complete()
  var observable = newObservable[int](subsribe)
  var observer = newObserver[int](onNext, onError, onCompleted)
  var dispsable = observable.subscribe( observer )
  var dispsable2 = observable.subscribe( observer )


 
  
