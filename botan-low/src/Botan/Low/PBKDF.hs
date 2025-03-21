{-|
Module      : Botan.Low.PBKDF
Description : Passphrase-based key derivation functions
Copyright   : (c) Leo D, 2023
License     : BSD-3-Clause
Maintainer  : leo@apotheca.io
Stability   : experimental
Portability : POSIX
-}

module Botan.Low.PBKDF where


-- /*
-- * Derive a key from a passphrase for a number of iterations
-- * @param pbkdf_algo PBKDF algorithm, e.g., "PBKDF2(SHA-256)"
-- * @param out buffer to store the derived key, must be of out_len bytes
-- * @param out_len the desired length of the key to produce
-- * @param passphrase the password to derive the key from
-- * @param salt a randomly chosen salt
-- * @param salt_len length of salt in bytes
-- * @param iterations the number of iterations to use (use 10K or more)
-- * @return 0 on success, a negative value on failure
-- *
-- * Deprecated: use
-- *  botan_pwdhash(pbkdf_algo, iterations, 0, 0, out, out_len,
-- *                passphrase, 0, salt, salt_len);
-- */
-- BOTAN_DEPRECATED("Use botan_pwdhash")
-- BOTAN_PUBLIC_API(2,0) int
-- botan_pbkdf(const char* pbkdf_algo,
--             uint8_t out[], size_t out_len,
--             const char* passphrase,
--             const uint8_t salt[], size_t salt_len,
--             size_t iterations);

-- /**
-- * Derive a key from a passphrase, running until msec time has elapsed.
-- * @param pbkdf_algo PBKDF algorithm, e.g., "PBKDF2(SHA-256)"
-- * @param out buffer to store the derived key, must be of out_len bytes
-- * @param out_len the desired length of the key to produce
-- * @param passphrase the password to derive the key from
-- * @param salt a randomly chosen salt
-- * @param salt_len length of salt in bytes
-- * @param milliseconds_to_run if iterations is zero, then instead the PBKDF is
-- *        run until milliseconds_to_run milliseconds has passed
-- * @param out_iterations_used set to the number iterations executed
-- * @return 0 on success, a negative value on failure
-- *
-- * Deprecated: use
-- *
-- * botan_pwdhash_timed(pbkdf_algo,
-- *                     static_cast<uint32_t>(ms_to_run),
-- *                     iterations_used,
-- *                     nullptr,
-- *                     nullptr,
-- *                     out, out_len,
-- *                     password, 0,
-- *                     salt, salt_len);
-- */
-- BOTAN_PUBLIC_API(2,0) int botan_pbkdf_timed(const char* pbkdf_algo,
--                                 uint8_t out[], size_t out_len,
--                                 const char* passphrase,
--                                 const uint8_t salt[], size_t salt_len,
--                                 size_t milliseconds_to_run,
--                                 size_t* out_iterations_used);
