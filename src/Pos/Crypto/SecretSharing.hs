{-# LANGUAGE DeriveGeneric   #-}
{-# LANGUAGE TemplateHaskell #-}

-- | Dummy implementation of VSS. It doesn't have any logic now.

module Pos.Crypto.SecretSharing
       ( VssPublicKey
       , getVssPublicKey
       , VssSecretKey
       , getVssSecretKey
       , deriveVssPublicKey
       , vssKeyGen
       , deterministicVssKeyGen

       , EncShare
       , Secret (..)
       , SecretProof
       , Share
       , decryptShare
       , encryptShare
       , recoverSecret
       , shareSecret
       , verifyProof
       ) where

import           Data.Binary          (Binary)
import           Data.Hashable        (Hashable)
import           Data.MessagePack     (MessagePack)
import           Data.SafeCopy        (base, deriveSafeCopySimple)
import           Data.Text.Buildable  (Buildable)
import qualified Data.Text.Buildable  as Buildable
import           Universum

import qualified Serokell.Util.Base16 as B16

import           Pos.Util             ()

-- | This key is used as part of VSS. Corresponding VssSecretKey may
-- be used to decrypt one of the shares.
newtype VssPublicKey = VssPublicKey
    { getVssPublicKey :: NotImplemented
    } deriving (Show, Eq, Ord, Binary, Generic, Hashable)

instance MessagePack VssPublicKey

-- | This key is to decrypt share generated by VSS.
newtype VssSecretKey = VssSecretKey
    { getVssSecretKey :: NotImplemented
    } deriving (Show, Eq, Ord, Binary, Generic)

instance MessagePack VssSecretKey

-- | Derive VssPublicKey from VssSecretKey.
deriveVssPublicKey :: VssSecretKey -> VssPublicKey
deriveVssPublicKey _ = VssPublicKey NotImplemented

vssKeyGen :: MonadIO m => m (VssPublicKey, VssSecretKey)
vssKeyGen = pure (VssPublicKey NotImplemented, VssSecretKey NotImplemented)

deterministicVssKeyGen :: ByteString -> (VssPublicKey, VssSecretKey)
deterministicVssKeyGen _ = (VssPublicKey NotImplemented, VssSecretKey NotImplemented)

-- | Secret can be split into encrypted shares to be reconstructed later.
newtype Secret = Secret
    { getSecret :: ByteString
    } deriving (Show, Eq, Ord, Binary, Generic)

instance MessagePack Secret

instance Buildable Secret where
    build = B16.formatBase16 . getSecret

-- | Shares can be used to reconstruct Secret.
data Share = Share
    { getShare   :: Secret
    , minNeeded  :: Word
    , shareIndex :: Word
    } deriving (Eq, Ord, Show, Generic)

instance Binary Share
instance MessagePack Share

instance Buildable Share where
    build _ = "share ¯\\_(ツ)_/¯"

-- | Encrypted share which needs to be decrypted using VssSecretKey first.
newtype EncShare = EncShare
    { getEncShare :: Share
    } deriving (Show, Eq, Ord, Generic, Binary)

instance MessagePack EncShare

instance Buildable EncShare where
    build _ = "encrypted share ¯\\_(ツ)_/¯"

-- | Decrypt share using secret key.
decryptShare :: VssSecretKey -> EncShare -> Share
decryptShare _ = getEncShare

-- | Encrypt share using public key.
encryptShare :: VssPublicKey -> Share -> EncShare
encryptShare _ = EncShare

-- | This proof may be used to check that particular given secret has
-- been generated.
newtype SecretProof =
    SecretProof Secret
    deriving (Show, Eq, Generic, Binary)

instance MessagePack SecretProof

shareSecret
    :: [VssPublicKey]  -- ^ Public keys of parties
    -> Word            -- ^ How many parts should be enough
    -> Secret          -- ^ Secret to share
    -> (SecretProof, [EncShare])  -- ^ i-th share is encrypted using i-th key
shareSecret keys k s = (SecretProof s, zipWith mkShare [0..] keys)
  where
    mkShare i key = encryptShare key (Share s k i)

recoverSecret :: [Share] -> Maybe Secret
recoverSecret [] = Nothing
recoverSecret (x:xs) = do
    guard (all (== getShare x) (map getShare xs))
    guard (length (ordNub (map shareIndex (x:xs))) >=
           fromIntegral (minNeeded x))
    return (getShare x)

verifyProof :: SecretProof -> Secret -> Bool
verifyProof (SecretProof p) s = p == s

----------------------------------------------------------------------------
-- SafeCopy instances
----------------------------------------------------------------------------

deriveSafeCopySimple 0 'base ''VssPublicKey
deriveSafeCopySimple 0 'base ''VssSecretKey
deriveSafeCopySimple 0 'base ''EncShare
deriveSafeCopySimple 0 'base ''Secret
deriveSafeCopySimple 0 'base ''SecretProof
deriveSafeCopySimple 0 'base ''Share
