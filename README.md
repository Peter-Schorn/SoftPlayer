# SoftPlayer

**Control Spotify playback from your menu bar.**

https://www.soft-player.com/

[<img src="https://www.soft-player.com/assets/app%20store.svg">](https://apps.apple.com/us/app/soft-player/id1573149282?mt=12)

![soft player screenshot](https://www.soft-player.com/assets/screenshots/player%20view%20with%20track.png)

## Running From Xcode

To run from Xcode, you must create a Spotify developer application on the [Spotify Developer Dashboard](https://developer.spotify.com/dashboard/login)., Then, you must configure and run an instance of [SpotifyAPI Server](https://github.com/Peter-Schorn/SpotifyAPIServer). You can run it locally from Xcode, as described in the README, at the same time you run Soft Player.

Requires the following environment variables:

<table>
  <thead>
    <tr>
      <th>Name</th>
      <th>Value</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>CLIENT_ID</code></td>
      <td>your client id</td>
    </tr>
    <tr>
      <td><code>TOKENS_URL</code></td>
      <td>The URL for retrieving tokens. If running locally on Xcode: <code>http://127.0.0.1:7000/authorization-code-flow-pkce/retrieve-tokens</code></td>
    </tr>
    <tr>
      <td><code>TOKENS_REFRESH_URL</code></td>
      <td>The URL for refreshing the access token: If running locally on Xcode: <code>http://127.0.0.1:7000/authorization-code-flow-pkce/refresh-tokens</code></td>
    </tr>
  </tbody>
</table>
