import Network.MateLight.Simple
import Network.MateLight

import SDLEventProvider.SDLKeyEventProvider

import Control.Monad.State
import Control.Monad.Reader

import Data.Maybe
import qualified Network.Socket as Sock

type KeyStatus = (String, String, Integer) -- Represents the tuple (KeyStatusString, KeyNameString, Time) 

{-
COLOR CODES:
Background -> Pixel 240 248 255 (Light Blue)
Ground     -> Pixel 160 82 45   (Brown)
Pixelsaur  -> Pixel 0 158 130   (Green)
Cactus     -> Pixel 0 100 0	    (Dark Green)
Bird       -> Pixel 220 20 60   (Red)
-}


move :: (Int, Int) -> KeyStatus -> (Int, Int) -> (Int, Int)
move (xdim, ydim) ("Pressed","UP",_) (x,y) = (x, (y - 1) `mod` ydim)
move (xdim, ydim) ("Held","UP",dur) (x,y) = if dur >= 100 then (x, (y - 1) `mod` ydim) else (x,y)
--move (xdim, ydim) ("Pressed","LEFT",_) (x,y) = ((x - 1) `mod` xdim, y)
--move (xdim, ydim) ("Held","LEFT",dur) (x,y) = if dur >= 100 then ((x - 1) `mod` xdim, y) else (x,y)
move (xdim, ydim) ("Pressed","DOWN",_) (x,y) = (x, (y + 1) `mod` ydim)
move (xdim, ydim) ("Held","DOWN",dur) (x,y) = if dur >= 100 then (x, (y + 1) `mod` ydim) else (x,y)
--move (xdim, ydim) ("Pressed","RIGHT",_) (x,y) = ((x + 1) `mod` xdim, y)
--move (xdim, ydim) ("Held","RIGHT",dur) (x,y) = if dur >= 100 then ((x + 1) `mod` xdim, y) else (x,y)
move _ _ (x,y) = (x,y)

-- Ground
ground :: (Int, Int) -> (Int, Int) -> ListFrame
ground (xdim, ydim) (x', y') = ListFrame $ map (\y -> map (\x -> if x == x' && y == y' then Pixel 160 82 45 else myGround x y) [0 .. xdim - 1]) [0 .. ydim - 1]

myGround :: Int -> Int -> Pixel
myGround x y | y == 11 = Pixel 160 82 45
             | otherwise = Pixel 240 248 255 

-- Pixelsaur (3 pixels high)
--pixelsaur :: (Int, Int) -> (Int, Int) -> ListFrame
--pixelsaur (xdim, ydim) (x', y') = ListFrame $ map (\y -> map (\x -> if x == x' && y == y' then Pixel 0 158 130 else Pixel 240 248 255) [0 .. xdim - 1]) [0 .. ydim - 1]


getKeyDataTuples keyState = (map (\(k,t) -> ("Pressed",k,t)) (pressed $ keyState)) ++ (map (\(k,d) -> ("Held",k,d)) (held $ keyState)) ++ (map (\(k,t) -> ("Released",k,t)) (released $ keyState))

eventTest :: [EventT] -> MateMonad ListFrame (Int,Int) IO ListFrame
eventTest events = do 
        state <- get
        let state' = foldl (\acc (EventT mod ev) -> if mod == "SDL_KEY_DATA" then foldl (\accState key -> move dim key accState) acc (getKeyDataTuples (read $ show ev)) else acc) state events
        put $ state'
        return (ground dim state') 

dim :: (Int, Int)
dim = (30, 12)
  
main :: IO ()
main = do
    showSDLControlWindow
    Sock.withSocketsDo $ runMateM (Config (fromJust $ parseAddress "134.28.70.172") 1337 dim (Just 33000) True [sdlKeyEventProvider]) eventTest (0,11) 
