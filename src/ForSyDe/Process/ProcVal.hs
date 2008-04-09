-----------------------------------------------------------------------------
-- |
-- Module      :  ForSyDe.Process.ProcVal
-- Copyright   :  (c) The ForSyDe Team 2007
-- License     :  BSD-style (see the file LICENSE)
-- 
-- Maintainer  :  ecs_forsyde_development@ict.kth.se
-- Stability   :  experimental
-- Portability :  non-portable (Template Haskell)
--
-- This module provides a type ('ProcVal') to store the value arguments passed
-- to process constructors.
--
----------------------------------------------------------------------------- 
module ForSyDe.Process.ProcVal where


import Data.Typeable (Typeable(..), TypeRep)
import Data.Dynamic (toDyn, Dynamic)
import Language.Haskell.TH (Exp, runQ)
import Language.Haskell.TH.Syntax (Lift(..))
import System.IO.Unsafe (unsafePerformIO)


data ProcVal = ProcVal 
                  {dyn     :: Dynamic,    --  Dynamic value 
                   valAST  :: ProcValAST} --  its AST

data ProcValAST = ProcValAST
                    {expVal :: Exp,       --  Its AST representation
                     expTyp :: TypeRep}    --  Type of the value   

-- | 'ProcVal' constructor
mkProcVal :: (Lift a, Typeable a) => a -> ProcVal
-- FIXME: would unsafePerformIO cause any harm to get the exp out of the
--        Q monad in this context?
mkProcVal val = ProcVal (toDyn val) (mkProcValAST val)

mkProcValAST :: (Lift a, Typeable a) => a -> ProcValAST 
mkProcValAST val = ProcValAST (unsafePerformIO.runQ.lift $ val) (typeOf val) 