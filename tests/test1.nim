# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest
import rxnim

test "can add":
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
  
