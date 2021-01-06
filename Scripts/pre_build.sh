cd $SRCROOT
cd SpotifyMenuBar/Model

source /Users/pschorn/.local/swift_testing_environment.sh

sed -r -i '' "s/(let __clientId__ = )\".*\"/\1\"$SPOTIFY_SWIFT_TESTING_CLIENT_ID\"/" 'Spotify.swift'
sed -r -i '' "s/(let __clientSecret__ = )\".*\"/\1\"$SPOTIFY_SWIFT_TESTING_CLIENT_SECRET\"/" 'Spotify.swift'
