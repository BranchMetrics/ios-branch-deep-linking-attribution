const fs = require('fs');

async function uploadAsset({ github, context, releaseId, assetName, path }) {
  const contents = fs.readFileSync(path);

  console.log(`Uploading asset ${assetName}...`);

  const { data } = await github.repos.uploadReleaseAsset({
    owner: context.repo.owner,
    repo: context.repo.repo,
    release_id: releaseId,
    name: assetName,
    data: contents,
  });

  console.log('Done ✅.');

  return data;
}

module.exports = uploadAsset;
