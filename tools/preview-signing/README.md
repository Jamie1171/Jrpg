# Public preview identity

`debug.keystore` is an intentionally public **test** key for the package
`org.jamie1171.unfinisheddawn.preview`. Alias: `androiddebugkey`; password: `android`.
It contains no account, repository or production credentials.

Keeping one test identity lets previews from this repository update the installed
preview without requiring an uninstall and losing its local save. Only install
APKs obtained from this repository's releases.

Never use this key or package identity for a store release. Before distribution
beyond this prototype, create a private production signing key, store it outside
the repository, and use a separate production package. A public test signature
does not establish the trust of a production publisher.
