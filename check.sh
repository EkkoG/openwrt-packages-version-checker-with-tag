if [ -z $MAKEFILE ]; then
    MAKEFILE=Makefile
fi

hash_version=$(curl https://api.github.com/repos/$REPO/git/refs/tags/$TAG | jq -r '.object.sha' | cut -c1-7)
# get tar file
wget https://codeload.github.com/$REPO/tar.gz/$TAG -O output.tar.gz
hash=$(sha256sum output.tar.gz | cut -d " " -f 1)
current_hash=$(cat $MAKEFILE | grep PKG_HASH | head -n 1 | cut -d "=" -f 2)
echo "Current hash: $current_hash"
if [ $current_hash = $hash ]; then
    echo "Hash not changed"
    exit 0
fi
echo "Hash changed, new hash: $hash"

sed -i "s/PKG_VERSION:=.*/PKG_VERSION:=$hash_version/g" $MAKEFILE
sed -i "s/PKG_RELEASE:=.*/PKG_RELEASE:=1/g" $MAKEFILE
sed -i "s/PKG_HASH:=.*/PKG_HASH:=$hash/g" $MAKEFILE

git config user.name "bot"
git config user.email "bot@github.com"
git add .
if [ -z "$(git status --porcelain)" ]; then
    echo "No changes to commit"
    exit 0
fi

if [ -z $BRANCH ]; then
    BRANCH=main
fi

git commit -m "$(TZ='Asia/Shanghai' date +@%Y%m%d) Bump $REPO to $hash_version"

if [ ! -z $CREATE_PR ]; then
    PR_BRANCH="auto-update/$REPO-$hash_version"
    git push "https://x-access-token:$COMMIT_TOKEN@github.com/$GITHUB_REPOSITORY" HEAD:$PR_BRANCH
    gh pr create --title "Bump $REPO to $hash_version" --body "Bump $REPO to $hash_version" --base $BRANCH --head $PR_BRANCH
else
    git push "https://x-access-token:$COMMIT_TOKEN@github.com/$GITHUB_REPOSITORY" HEAD:$BRANCH
fi