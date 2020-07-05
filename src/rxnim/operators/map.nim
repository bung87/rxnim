import ../observable
import ../observer

type 
  OperatorFunction[T, R] = proc (source: Observable[T]):Subscribale[T,R]
  MapOperator[T,R] = object of Operator[T,R]
    project:proc(value: T, index: int):R
  MapSubscriber[T,R] = object
    count:int
    destination:Observer[R]

proc map*[T,R](project:proc(value:T,index:int):R):OperatorFunction[T, R] =
  result = proc (source: Observable[T]): Subscribale[T,R] =
    source.lift(MapOperator[T,R](project:project))

proc next*[T,R](self:MapSubscriber[T,R],value:T):void =
  var val:R
  try:
    val = self.project( value, self.count)
  except Exception as err:
      self.destination.error(err)
      return
  self.destination.next(val)
  self.count = self.count + 1

proc newMapSubscriber[T,R](destination: Observer[R], project:proc (value: T, index: int):R) :MapSubscriber[T,R] =
  result.destination = destination
  result.project = project

proc call*[T,R](self:MapOperator[T, R],subscriber:Observer[R],source:Observer[T]):Disposable[T] =
  source.subscribe( newMapSubscriber(subscriber,self.project))


  
# export class MapOperator<T, R> implements Operator<T, R> {
#   constructor(private project: (value: T, index: number) => R, private thisArg: any) {
#   }

#   call(subscriber: Subscriber<R>, source: any): any {
#     return source.subscribe(new MapSubscriber(subscriber, this.project, this.thisArg));
#   }
# }

# class MapSubscriber<T, R> extends Subscriber<T> {
#   count: number = 0;
#   private thisArg: any;

#   constructor(destination: Subscriber<R>,
#               private project: (value: T, index: number) => R,
#               thisArg: any) {
#     super(destination);
#     this.thisArg = thisArg || this;
#   }

#   // NOTE: This looks unoptimized, but it's actually purposefully NOT
#   // using try/catch optimizations.
#   protected _next(value: T) {
#     let result: R;
#     try {
#       result = this.project.call(this.thisArg, value, this.count++);
#     } catch (err) {
#       this.destination.error(err);
#       return;
#     }
#     this.destination.next(result);
#   }
# }