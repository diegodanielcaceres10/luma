declare module 'rxjs' {
  export interface Observable<T> {
    subscribe(next?: (value: T) => void, error?: (error: any) => void, complete?: () => void): any;
    pipe<A>(op1: (source: Observable<T>) => Observable<A>): Observable<A>;
    pipe(...operations: any[]): Observable<any>;
  }
  export function filter<T, S extends T>(predicate: (value: T, index: number) => value is S): (source: Observable<T>) => Observable<S>;
  export function filter<T>(predicate: (value: T, index: number) => boolean): (source: Observable<T>) => Observable<T>;
  export const Observable: any;
  export const Subject: any;
  export const Subscription: any;
}
