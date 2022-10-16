cd $CI_WORKSPACE
cd SoftPlayer/Model

sed -r -i '' "s~(let __clientId__ = )\".*\"~\1\"$CLIENT_ID\"~" 'Spotify.swift'

sed -r -i '' "s~(let __tokensURL__ = )\".*\"~\1\"$TOKENS_URL\"~" 'Spotify.swift'
sed -r -i '' "s~(let __tokensRefreshURL__ = )\".*\"~\1\"$TOKENS_REFRESH_URL\"~" 'Spotify.swift'
