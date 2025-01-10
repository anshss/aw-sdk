# `@lit-protocol/aw-signer`

## Unreleased

### Changed

- (#26) A PKP is no longer automatically minted when an `Admin` is initialized.
- (#26) All `public` methods in `Admin` now expect `pkpTokenId: string` as an argument in order to fetch the PKP from local storage.

### Added

- (#26) Added new methods to the `Admin` class:
  - `getPkps`: Returns an array of `PkpInfo` objects from local storage.
  - `getPkpByTokenId`: Returns a `PkpInfo` object from local storage by its token ID.
  - `mintPkp`: Mints a new PKP, adds it's `PkpInfo` object to local storage, and returns the `PkpInfo` object.
  - `transferPkpOwnership`: Transfers ownership of a PKP to a new owner, removes the `PkpInfo` object from local storage, and returns the transaction receipt.
