VERSION="$1"
PREFIXED_VERSION="v$1"
NOTES="$2"

# Update version number
#

# Update Carthage release json file
jq --indent 3 '. += {'"\"$VERSION\""': "'"https://github.com/mparticle-integrations/mparticle-apple-integration-adjust/releases/download/$PREFIXED_VERSION/mParticle_Adjust.framework.zip?alt=https://github.com/mparticle-integrations/mparticle-apple-integration-adjust/releases/download/$PREFIXED_VERSION/mParticle_Adjust.xcframework.zip"'"}'
mParticle_Adjust.json > tmp.json
mv tmp.json mParticle_Adjust.json

# Update CocoaPods podspec file
sed -i '' 's/\(^    s.version[^=]*= \).*/\1"'"$VERSION"'"/' mParticle-Adjust.podspec

# Make the release commit in git
#

git add mParticle-Adjust.podspec
git add mParticle_Adjust.json
git add CHANGELOG.md
git commit -m "chore(release): $VERSION [skip ci]

$NOTES"
