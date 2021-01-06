cd $PROJECT_DIR
cd SpotifyMenuBar/Model

sed -r -i '' 's/(let __clientId__ = )".*"/\1""/' 'Spotify.swift'
sed -r -i '' 's/(let __clientSecret__ = )".*"/\1""/' 'Spotify.swift'
