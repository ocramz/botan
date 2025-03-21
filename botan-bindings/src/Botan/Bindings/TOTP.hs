{-|
Module      : Botan.Bindings.TOTP
Description : Time-based one time passwords
Copyright   : (c) Leo D, 2023
License     : BSD-3-Clause
Maintainer  : leo@apotheca.io
Stability   : experimental
Portability : POSIX

One time password schemes are a user authentication method that
relies on a fixed secret key which is used to derive a sequence
of short passwords, each of which is accepted only once. Commonly
this is used to implement two-factor authentication (2FA), where
the user authenticates using both a conventional password (or a
public key signature) and an OTP generated by a small device such
as a mobile phone.

Botan implements the HOTP and TOTP schemes from RFC 4226 and 6238.

Since the range of possible OTPs is quite small, applications must
rate limit OTP authentication attempts to some small number per 
second. Otherwise an attacker could quickly try all 1000000 6-digit
OTPs in a brief amount of time.

HOTP generates OTPs that are a short numeric sequence, between 6
and 8 digits (most applications use 6 digits), created using the
HMAC of a 64-bit counter value. If the counter ever repeats the
OTP will also repeat, thus both parties must assure the counter
only increments and is never repeated or decremented. Thus both
client and server must keep track of the next counter expected.

Anyone with access to the client-specific secret key can authenticate
as that client, so it should be treated with the same security
consideration as would be given to any other symmetric key or
plaintext password.

TOTP is based on the same algorithm as HOTP, but instead of a
counter a timestamp is used.
-}

module Botan.Bindings.TOTP where

import Botan.Bindings.Error
import Botan.Bindings.Prelude

-- NOTE: RFC 6238

{-|
TOTP

@typedef struct botan_totp_struct* botan_totp_t;@
-}

data TOTPStruct
type TOTPPtr = Ptr TOTPStruct

type TOTPCode = Word32
type TOTPTimestep = Word64
type TOTPTimestamp = Word64

{-|
Initialize a TOTP instance

@BOTAN_PUBLIC_API(2,8)
int botan_totp_init(botan_totp_t* totp,
                    const uint8_t key[], size_t key_len,
                    const char* hash_algo,
                    size_t digits,
                    size_t time_step);@
-}
foreign import ccall unsafe botan_totp_init
    :: Ptr TOTPPtr
    -> Ptr Word8 -> CSize
    -> CString
    -> CSize
    -> CSize
    -> IO BotanErrorCode

{-|
Destroy a TOTP instance
- \@return 0 if success, error if invalid object handle

@BOTAN_PUBLIC_API(2,8)
int botan_totp_destroy(botan_totp_t totp);@
-}
foreign import ccall unsafe "&botan_totp_destroy" botan_totp_destroy :: FinalizerPtr TOTPStruct

{-|
Generate a TOTP code for the provided timestamp
- \@param totp the TOTP object
- \@param totp_code the OTP code will be written here
- \@param timestamp the current local timestamp

@BOTAN_PUBLIC_API(2,8)
int botan_totp_generate(botan_totp_t totp,
                        uint32_t* totp_code,
                        uint64_t timestamp);@
-}
foreign import ccall unsafe botan_totp_generate
    :: TOTPPtr
    -> Ptr TOTPCode
    -> TOTPTimestamp
    -> IO BotanErrorCode

{-|
Verify a TOTP code
- \@param totp the TOTP object
- \@param totp_code the presented OTP
- \@param timestamp the current local timestamp
- \@param acceptable_clock_drift specifies the acceptable amount
of clock drift (in terms of time steps) between the two hosts.

@BOTAN_PUBLIC_API(2,8)
int botan_totp_check(botan_totp_t totp,
                     uint32_t totp_code,
                     uint64_t timestamp,
                     size_t acceptable_clock_drift);@
-}
foreign import ccall unsafe botan_totp_check
    :: TOTPPtr
    -> TOTPCode
    -> TOTPTimestamp
    -> CSize
    -> IO BotanErrorCode
