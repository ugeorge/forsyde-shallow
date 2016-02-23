module DELib where

import ForSyDe.Shallow.Signal
       
type Time = Int

data DEToken a = U | D a deriving (Eq, Show, Ord)

-- delayDE without cleaning
delayDE :: Time -> DEToken a -> Signal (Time, DEToken a) -> Signal (Time, DEToken a) 
delayDE delta s0 xs = (0, s0) :- delayDE' delta s0 xs

delayDE' delta s0 NullS       = NullS
delayDE' delta s0 ((t,v):-xs) = (t+delta,v) :- delayDE' delta s0 xs


{-
delayDE delta s0 xs = (0, s0) :- delayDE' delta s0 s0 xs

delayDE' delta s0 s NullS       = NullS
delayDE' delta s0 s ((t,v):-xs) = if v /= s then
                                     (t+delta,v) :- delayDE' delta s0 v xs
                                  else
                                     delayDE' delta s0 s xs
-}
                                     

-- FIXME: mapDE shall only take non-lifted functions!
mapDE :: Eq a => (DEToken a -> DEToken a) -> Signal (Time, DEToken a) -> Signal (Time, DEToken a)  
mapDE f = mapDE' f U

mapDE' f _ NullS       = NullS
mapDE' f U ((t,v):-xs) = (t,f v) :- mapDE' f v xs
mapDE' f w ((t,v):-xs) = if (f v) == w then
                            mapDE' f w xs
                         else
                            (t, (f v)) :- mapDE' f (f v) xs 

-- FIXME: Add old values on the inputs to zipWithDE - More patterns needed!
zipWithDE :: Ord a => (DEToken a -> DEToken a -> DEToken a) -> Signal (Time, DEToken a) -> Signal (Time, DEToken a) -> Signal (Time, DEToken a)    
zipWithDE f = zipWithDE' f U U U

zipWithDE' f _ _ _ NullS          NullS          = NullS
zipWithDE' f _ _ _ _              NullS          = NullS           
zipWithDE' f _ _ _ NullS          _              = NullS
zipWithDE' f _ _ U ((tx, vx):-xs) ((ty, vy):-ys)
   = if tx < ty then
        zipWithDE' f vx U U xs ((ty, vy):-ys)
     else 
        if ty > tx then
           zipWithDE' f U vy U ((tx, vx):-xs) ys
        else          
           (tx, f vx vy) :- zipWithDE' f vx vy (f vx vy) xs ys
zipWithDE' f x y w ((tx, vx):-xs) ((ty, vy):-ys)
   = if tx < ty then
        zipWithDE' f vx y (f vx y) xs ((ty, vy):-ys)
     else 
        if ty > tx then
           zipWithDE' f x vy (f x vy) ((tx, vx):-xs) ys
        else          
           (tx, f vx vy) :- zipWithDE' f vx vy (f vx vy) xs ys


liftDE f U     = U
liftDE f (D x) = D (f x)

lift2DE f U     _     = U
lift2DE f _     U     = U
lift2DE f (D x) (D y) = D (f x y) 

incDE = liftDE (+ 1)
idDE = liftDE (id)
addDE = lift2DE (+)

sourceDE1 = out
  where
    out = mapDE incDE s
    s   = delayDE 1 (D 0) out
 
sourceDE2 = out
  where
    out = mapDE idDE s
    s   = delayDE 1 (D 0) out

system s1 = out
   where out = zipWithDE addDE s1 i1
         i1 = delayDE 2 (D 2) out

s1 = (10, D 1) :- (20, D 2) :- NullS
s2 = (15, D 10) :- (18, D 20) :- NullS 

-- Test cases
test1 = delayDE 1 (D 1) s1

test2 = mapDE incDE s1

test3 = zipWithDE addDE s1 s2

test4 = sourceDE1

test5 = sourceDE2

test6 = system s1
      
