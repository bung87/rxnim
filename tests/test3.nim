import unittest
import rxnim
import rxnim/operators/map

test "map operator":
  var onNext = proc(value:int):void = 
    check value == 1
    echo "from1"
  var onError = proc(error:Exception):void = 
    echo $error
  var onCompleted = proc():void = 
    echo "done"
  var mapFunc = proc(value:int,index:int):int =
    return value + 1
  var observer = newObserver[int](onNext, onError, onCompleted)
  var observable = newObservable[int]()
  var dispsable = observable.pipe[int,int](map[int,int](mapFunc)).subscribe( observer )
  observer.next(1)
