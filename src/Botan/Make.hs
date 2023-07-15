module Botan.Make where

import Prelude

import Control.Monad

import Data.ByteString (ByteString)
import qualified Data.ByteString as ByteString

import Data.Word

import System.IO

import Foreign.C.String
import Foreign.C.Types
import Foreign.ForeignPtr
import Foreign.Marshal.Alloc
import Foreign.Ptr
import Foreign.Storable

import Botan.Error
import Botan.Prelude

{-
Basic botan type template
-}

{-
data TypStruct
type TypPtr = Ptr (TypStruct)

newtype Typ = MkTyp { getTypForeignPtr :: ForeignPtr (TypStruct) }

withTypPtr :: Typ -> (TypPtr -> IO a) -> IO a
withTypPtr = withForeignPtr . getTypForeignPtr

-- Common / optional associated types
type TypName = ByteString
type TypFlags = Word32
-}

{-
Helper types
-}

type WithPtr typ ptr = (forall a . typ -> (ptr -> IO a) -> IO a)

{-
Initializers and destroyers
-}

type Constr struct typ = ForeignPtr struct -> typ

type Initializer struct = Ptr (Ptr struct) -> IO BotanErrorCode
type Initializer_name struct = Ptr (Ptr struct) -> CString -> IO BotanErrorCode
type Initializer_name_flags struct = Ptr (Ptr struct) -> CString -> Word32 -> IO BotanErrorCode

type Destructor struct = FinalizerPtr struct

mkInit
    :: Constr struct typ
    -> Initializer struct
    -> Destructor struct
    -> IO typ
mkInit constr init destroy = do
    alloca $ \ outPtr -> do
        throwBotanIfNegative_ $ init outPtr
        out <- peek outPtr
        foreignPtr <- newForeignPtr destroy out
        return $ constr foreignPtr

mkInit_name
    :: Constr struct typ
    -> Initializer_name struct
    -> Destructor struct
    -> ByteString -> IO typ
mkInit_name constr init destroy name = do
    alloca $ \ outPtr -> do
        asCString name $ \ namePtr -> do 
            throwBotanIfNegative_ $ init outPtr namePtr
        out <- peek outPtr
        foreignPtr <- newForeignPtr destroy out
        return $ constr foreignPtr

mkInit_name_flags
    :: Constr struct typ
    -> Initializer_name_flags struct
    -> Destructor struct
    -> ByteString -> Word32 -> IO typ
mkInit_name_flags constr init destroy name flags = do
    alloca $ \ outPtr -> do
        asCString name $ \ namePtr -> do 
            throwBotanIfNegative_ $ init outPtr namePtr flags
        out <- peek outPtr
        foreignPtr <- newForeignPtr destroy out
        return $ constr foreignPtr

{-
Non-effectful queries
-}

type GetName ptr = ptr -> Ptr CChar -> Ptr CSize -> IO BotanErrorCode

mkGetName
    :: WithPtr typ ptr
    -> GetName ptr
    -> typ -> IO ByteString
mkGetName withPtr get typ = withPtr typ $ \ typPtr -> do
    -- TODO: use ByteString.Internal.createAndTrim?
    -- NOTE: This uses copy to mimic ByteArray.take (which copies!) so we can drop the rest of the bytestring
    alloca $ \ szPtr -> do
        bytes <- allocBytes 64 $ \ bytesPtr -> do
            throwBotanIfNegative_ $ get typPtr bytesPtr szPtr
        sz <- peek szPtr
        return $ ByteString.copy $ ByteString.take (fromIntegral sz) bytes

type GetSize ptr = ptr -> Ptr CSize -> IO BotanErrorCode
type GetSize_csize ptr = ptr -> CSize -> Ptr CSize -> IO BotanErrorCode
type GetSizes2 ptr = ptr -> Ptr CSize -> Ptr CSize -> IO BotanErrorCode
type GetSizes3 ptr = ptr -> Ptr CSize -> Ptr CSize -> Ptr CSize -> IO BotanErrorCode

mkGetSize
    :: WithPtr typ ptr
    -> GetSize ptr
    -> typ -> IO Int
mkGetSize withPtr get typ = withPtr typ $ \ typPtr -> do
    alloca $ \ szPtr -> do
        throwBotanIfNegative_ $ get typPtr szPtr
        fromIntegral <$> peek szPtr

mkGetSize_csize
    :: WithPtr typ ptr
    -> GetSize_csize ptr
    -> typ -> Int -> IO Int
mkGetSize_csize withPtr get typ forSz = withPtr typ $ \ typPtr -> do
    alloca $ \ szPtr -> do
        throwBotanIfNegative_ $ get typPtr (fromIntegral forSz) szPtr
        fromIntegral <$> peek szPtr

mkGetSizes2
    :: WithPtr typ ptr
    -> GetSizes2 ptr
    -> typ -> IO (Int,Int)
mkGetSizes2 withPtr get typ = withPtr typ $ \ typPtr -> do
    alloca $ \ szPtrA -> alloca $ \ szPtrB -> do
        throwBotanIfNegative_ $ get typPtr szPtrA szPtrB
        szA <- fromIntegral <$> peek szPtrA
        szB <- fromIntegral <$> peek szPtrB
        return (szA,szB)

mkGetSizes3
    :: WithPtr typ ptr
    -> GetSizes3 ptr
    -> typ -> IO (Int,Int,Int)
mkGetSizes3 withPtr get typ = withPtr typ $ \ typPtr -> do
    alloca $ \ szPtrA -> alloca $ \ szPtrB -> alloca $ \ szPtrC -> do
        throwBotanIfNegative_ $ get typPtr szPtrA szPtrB szPtrC
        szA <- fromIntegral <$> peek szPtrA
        szB <- fromIntegral <$> peek szPtrB
        szC <- fromIntegral <$> peek szPtrC
        return (szA,szB,szC)

-- type GetBytes ptr = ptr -> Ptr Word8 -> CSize -> IO BotanErrorCode

type GetBoolCode ptr = ptr -> IO BotanErrorCode
type GetBoolCode_csize ptr = ptr -> CSize -> IO BotanErrorCode

mkGetBoolCode
    :: WithPtr typ ptr
    -> GetBoolCode ptr
    -> typ -> IO Bool
mkGetBoolCode withPtr get typ = withPtr typ $ \ typPtr -> do
    throwBotanCatchingBool $ get typPtr

mkGetBoolCode_csize
    :: WithPtr typ ptr
    -> GetBoolCode_csize ptr
    -> typ -> Int -> IO Bool
mkGetBoolCode_csize withPtr get typ sz = withPtr typ $ \ typPtr -> do
    throwBotanCatchingBool $ get typPtr (fromIntegral sz)

type GetIntCode ptr = ptr -> IO BotanErrorCode
type GetIntCode_csize ptr = ptr -> CSize -> IO BotanErrorCode

{-
Effectful actions
-}

type Action ptr = ptr -> IO BotanErrorCode
mkAction
    :: WithPtr typ ptr
    -> Action ptr
    -> typ -> IO ()
mkAction withPtr action typ = withPtr typ $ \ typPtr -> do
    throwBotanIfNegative_ $ action typPtr

type SetCString ptr = ptr -> CString -> IO BotanErrorCode
type SetBytesLen ptr = ptr -> Ptr Word8 -> CSize -> IO BotanErrorCode

mkSetCString
    :: WithPtr typ ptr
    -> SetCString ptr
    -> typ -> ByteString -> IO ()
mkSetCString withPtr set typ cstring = withPtr typ $ \ typPtr -> do
    asCString cstring $ \ cstringPtr -> do 
        throwBotanIfNegative_ $ set typPtr cstringPtr

mkSetBytesLen
    :: WithPtr typ ptr
    -> SetBytesLen ptr
    -> typ -> ByteString -> IO ()
mkSetBytesLen withPtr set typ bytes = withPtr typ $ \ typPtr -> do
    asBytesLen bytes $ \ bytesPtr bytesLen -> do 
        throwBotanIfNegative_ $ set typPtr bytesPtr bytesLen
