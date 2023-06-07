# SoftPlayer

**Control Spotify playback from your menu bar.**

https://www.soft-player.com/

[<img src="https://www.soft-player.com/assets/app%20store.svg">](https://apps.apple.com/us/app/soft-player/id1573149282?mt=12)

![soft player screenshot](https://www.soft-player.com/assets/screenshots/player%20view%20with%20track.png)

## Running From Xcode

To run from Xcode, you must create a Spotify developer application on the [Spotify Developer Dashboard](https://developer.spotify.com/dashboard/login). Add the following redirect URI:
```
peter-schorn-soft-player://login-callback
```

## Authorization Configuration

This application can be configured to use a backend server during the authorization process. Using this server provides enhanced security because the refresh token can be encrypted. The version on the App Store uses [SpotifyAPI Server](https://github.com/Peter-Schorn/SpotifyAPIServer), which you can run locally from Xcode, as described in the README, at the same time you run Soft Player.

For convenience, however, you can also run Soft Player without relying on any backend server. To do this, use either the `Debug Local Authorization` or `Release Local Authorization` build configuration in your scheme:

![scheme build configurations](https://github.com/Peter-Schorn/SoftPlayer/assets/58197311/e14dfa11-1c30-4373-bc3c-36033bf84cff)

## Environment

Requires the following environment variables (in addition to those required by SpotifyAPI Server):

| Name | Value |
| --- | :-- |
| `CLIENT_ID` | Your client id. |
| `TOKENS_URL` | The URL for retrieving tokens. Not required if using the local authorization build configuration. If running SpotifyAPIServer locally on Xcode: `http://127.0.0.1:7000/authorization-code-flow-pkce/retrieve-tokens` |
| `TOKENS_REFRESH_URL` | The URL for refreshing the access token. Not required if using the local authorization build configuration. If running SpotifyAPIServer locally on Xcode: `http://127.0.0.1:7000/authorization-code-flow-pkce/refresh-tokens` |

Alternatively, you may set these values in a bash script at the following location: `~/.local/soft_player_credentials.sh`. For example:

```bash
export CLIENT_ID=abcabcabcbabc

# both not required if using the local authorization build configuration
export TOKENS_URL='http://127.0.0.1:7000/authorization-code-flow-pkce/retrieve-tokens'
export TOKENS_REFRESH_URL='http://127.0.0.1:7000/authorization-code-flow-pkce/refresh-tokens'
```

Then, configure the `Scripts/pre_build.sh` to run in the build pre-actions and `Scripts/post_build.sh` to run in the build post-actions of the scheme:

![build actions in scheme](https://github.com/Peter-Schorn/SoftPlayer/assets/58197311/afef6c28-325f-45a9-8ad0-848193c5d75e)

Lastly, you may also set these values at runtime using user defaults via the `defaults` bash utility. The keys are in lowerCamalCase: `clientId`,  `tokensURL`, `tokensRefreshURL`. For example:

```bash
# set the client id
defaults write Peter-Schorn.SoftPlayer clientId "your client id"

# read the tokensURL value
defaults read Peter-Schorn.SoftPlayer tokensURL

# delete the tokensRefreshURL value
defaults delete Peter-Schorn.SoftPlayer tokensRefreshURL

# read all values in user defaults for this app
defaults read Peter-Schorn.SoftPlayer
```

The pre-build script, if configured, takes precedence over environment variables, which take precedence over user defaults. You must re-launch the app for changes to these values to take effect. See [SoftPlayer/Model/Spotify.swift](https://github.com/Peter-Schorn/SoftPlayer/blob/main/SoftPlayer/Model/Spotify.swift) for where these values are accessed in code.
